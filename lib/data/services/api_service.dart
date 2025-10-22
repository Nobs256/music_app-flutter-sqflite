import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants.dart';
import '../models/media.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  final _dio = Dio();

  // In-memory cache variables
  List<Media>? _publicMediaCache;
  DateTime? _publicMediaCacheTimestamp;

  List<Media>? _userMediaCache;
  DateTime? _userMediaCacheTimestamp;
  int? _cachedUserId; // To ensure user cache is for the correct user

  static const _cacheDuration = Duration(minutes: 5);

  // A common User-Agent header to bypass simple bot detection on free hosts.
  final Map<String, String> _browserHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
  };

  /// Fetches a list of all media from the public endpoint. (GET /media.php)
  Future<List<Media>> getMedia({bool forceRefresh = false}) async {
    // Check if a valid cache exists
    if (!forceRefresh &&
        _publicMediaCache != null &&
        _publicMediaCacheTimestamp != null &&
        DateTime.now().difference(_publicMediaCacheTimestamp!) <
            _cacheDuration) {
      return _publicMediaCache!;
    }

    final response = await http.get(
      Uri.parse('$apiBaseUrl/media.php'),
      headers: _browserHeaders,
    );

    if (response.statusCode == 200) {
      // The API returns a JSON object with a 'media' key.
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['error'] == false && data['media'] != null) {
        // We pass the 'media' list to our model's fromJsonList method.
        // We need to re-encode it to a JSON string to fit the method signature.
        final mediaList = Media.fromJsonList(json.encode(data['media']));
        // Update cache
        _publicMediaCache = mediaList;
        _publicMediaCacheTimestamp = DateTime.now();
        return mediaList;
      } else {
        // If the API returns an error flag, throw an exception.
        throw Exception(data['message'] ?? 'Failed to load media');
      }
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception.
      throw Exception('Failed to load media from server');
    }
  }

  /// Registers a new user. (POST /register.php)
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/register.php'),
      headers: {..._browserHeaders, 'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    return json.decode(response.body);
  }

  /// Logs in a user and stores the token. (POST /login.php)
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/login.php'),
      headers: {..._browserHeaders, 'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    final data = json.decode(response.body);

    // If login is successful and a token is received, store it securely.
    if (data['error'] == false && data['token'] != null) {
      await _storage.write(key: 'jwt_token', value: data['token']);
    }

    return data;
  }

  /// Retrieves the stored JWT.
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  /// Deletes the stored JWT upon logout.
  Future<void> logout() async {
    // Clear user-specific cache on logout
    _userMediaCache = null;
    _userMediaCacheTimestamp = null;
    _cachedUserId = null;
    await _storage.delete(key: 'jwt_token');
  }

  /// Fetches media uploaded by the currently authenticated user. (GET /mymedia.php)
  Future<List<Media>> getMyMedia({bool forceRefresh = false}) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final userId = (JwtDecoder.decode(token)['data']['userId']) as int;

    // Check for a valid cache for the current user
    if (!forceRefresh &&
        _userMediaCache != null &&
        _userMediaCacheTimestamp != null &&
        _cachedUserId == userId &&
        DateTime.now().difference(_userMediaCacheTimestamp!) < _cacheDuration) {
      return _userMediaCache!;
    }

    final response = await http.get(
      Uri.parse('$apiBaseUrl/mymedia.php'),
      headers: {..._browserHeaders, 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['error'] == false && data['media'] != null) {
        final mediaList = Media.fromJsonList(json.encode(data['media']));
        // Update cache
        _userMediaCache = mediaList;
        _userMediaCacheTimestamp = DateTime.now();
        _cachedUserId = userId;
        return mediaList;
      } else {
        throw Exception(data['message'] ?? 'Failed to load your media');
      }
    } else {
      throw Exception('Failed to load your media from server');
    }
  }

  /// Decodes the username from the stored JWT.
  Future<String?> getUsernameFromToken() async {
    final token = await getToken();
    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      // The username is nested inside the 'data' object in the payload
      return decodedToken['data']['username'];
    }
    return null;
  }

  /// Uploads media to the server. (POST /upload.php)
  Future<Map<String, dynamic>> uploadMedia(
    String title,
    File mediaFile, {
    File? coverArtFile,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated. Cannot upload.');
    }

    // Invalidate user media cache after a successful upload
    _userMediaCache = null;
    _userMediaCacheTimestamp = null;
    _cachedUserId = null;

    var uri = Uri.parse('$apiBaseUrl/upload.php');
    var request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers.addAll({
      ..._browserHeaders,
      'Authorization': 'Bearer $token',
    });

    // Add text fields
    request.fields['title'] = title;

    // Add media file
    request.files.add(
      await http.MultipartFile.fromPath('mediaFile', mediaFile.path),
    );

    // Add cover art file if it exists
    if (coverArtFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('coverArtFile', coverArtFile.path),
      );
    }

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();

    return json.decode(responseBody);
  }

  /// Downloads a media file. (GET /download.php)
  Future<void> downloadMedia(
    int mediaId,
    String savePath, {
    Function(int, int)? onReceiveProgress,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated. Cannot download.');
    }

    try {
      await _dio.download(
        '$apiBaseUrl/download.php?id=$mediaId',
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: {..._browserHeaders, 'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  /// Toggles a favorite status for a media item. (POST /toggle_favorite.php)
  Future<Map<String, dynamic>> toggleFavorite(int mediaId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$apiBaseUrl/toggle_favorite.php'),
      headers: {
        ..._browserHeaders,
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'media_id': mediaId}),
    );

    return json.decode(response.body);
  }

  /// Fetches the user's favorited media. (GET /get_favorites.php)
  Future<List<Media>> getFavorites() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$apiBaseUrl/get_favorites.php'),
      headers: {..._browserHeaders, 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Media.fromJsonList(json.encode(data['media']));
    } else {
      throw Exception('Failed to load favorites');
    }
  }
}
