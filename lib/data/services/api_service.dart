import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:musicapp/data/models/media.dart';

class ApiService {
  // Replace with your actual base URL
  static const String _baseUrl = 'https://music.onlineincomehub.org/api';
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // --- Session Management ---

  Future<void> _saveSession(String userId, String username) async {
    await _secureStorage.write(key: 'user_id', value: userId);
    await _secureStorage.write(key: 'username', value: username);
  }

  Future<String?> getUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }

  Future<String?> getUsername() async {
    return await _secureStorage.read(key: 'username');
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }

  // --- API Methods ---

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await _dio.post(
      '$_baseUrl/register.php',
      data: {'username': username, 'email': email, 'password': password},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post(
      '$_baseUrl/login.php',
      data: {'username': username, 'password': password},
    );

    if (response.data['error'] == false) {
      // On successful login, save the session data.
      final userId = response.data['userId'].toString();
      final userUsername = response.data['username'].toString();
      await _saveSession(userId, userUsername);
    }
    return response.data;
  }

  Future<Map<String, dynamic>> uploadMedia(
    String title,
    File mediaFile, {
    File? coverArtFile,
  }) async {
    final userId = await getUserId();
    if (userId == null) {
      throw Exception('User is not logged in. Cannot upload media.');
    }

    final formData = FormData.fromMap({
      'user_id': userId,
      'title': title,
      'mediaFile': await MultipartFile.fromFile(
        mediaFile.path,
        filename: mediaFile.path.split('/').last,
      ),
    });

    if (coverArtFile != null) {
      formData.files.add(
        MapEntry(
          'coverArtFile',
          await MultipartFile.fromFile(
            coverArtFile.path,
            filename: coverArtFile.path.split('/').last,
          ),
        ),
      );
    }

    final response = await _dio.post('$_baseUrl/upload.php', data: formData);
    return response.data;
  }

  Future<List<Media>> getMedia() async {
    final userId = await getUserId();
    final response = await _dio.get(
      '$_baseUrl/media.php',
      queryParameters: userId != null ? {'user_id': userId} : null,
    );
    // Safely handle the response. If 'media' key is missing or null, return an empty list.
    if (response.data != null && response.data['media'] is List) {
      final List<dynamic> mediaJson = response.data['media'];
      return mediaJson.map((json) => Media.fromJson(json)).toList();
    } else {
      // Return an empty list if the data is not in the expected format.
      return [];
    }
  }

  Future<Map<String, dynamic>> getMyMedia({bool forceRefresh = false}) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('User not logged in');

    final response = await _dio.get(
      '$_baseUrl/mymedia.php',
      queryParameters: {'user_id': userId},
    );
    return response.data;
  }

  Future<List<Media>> getFavorites() async {
    final userId = await getUserId();
    if (userId == null) return [];

    final response = await _dio.get(
      '$_baseUrl/get_favorites.php',
      queryParameters: {'user_id': userId},
    );
    // Safely handle the response. The PHP script returns the list under the 'media' key.
    if (response.data != null && response.data['media'] is List) {
      final List<dynamic> mediaJson = response.data['media'];
      return mediaJson.map((json) => Media.fromJson(json)).toList();
    } else {
      // Return an empty list if the user has no favorites or if there's an API error.
      return [];
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(int mediaId) async {
    final userId = await getUserId();
    if (userId == null) {
      throw Exception('User not logged in. Cannot toggle favorite.');
    }
    final response = await _dio.post(
      '$_baseUrl/toggle_favorite.php',
      data: {'user_id': userId, 'media_id': mediaId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> editMedia(int mediaId, String title) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('User not logged in');

    final response = await _dio.post(
      '$_baseUrl/edit_media.php',
      data: {'media_id': mediaId, 'title': title, 'user_id': userId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteMedia(int mediaId) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('User not logged in');

    final response = await _dio.post(
      '$_baseUrl/delete_media.php',
      data: {'media_id': mediaId, 'user_id': userId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> toggleLike(int mediaId) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('User not logged in');

    final response = await _dio.post(
      '$_baseUrl/toggle_like.php',
      data: {'user_id': userId, 'media_id': mediaId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> toggleSubscription(int artistId) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('User not logged in');

    final response = await _dio.post(
      '$_baseUrl/toggle_subscription.php',
      data: {'user_id': userId, 'artist_id': artistId},
    );
    return response.data;
  }
}
