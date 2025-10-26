import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/media.dart';

class DatabaseService {
  final _storage = const FlutterSecureStorage();
  static Database? _database;
  static const String _dbName = 'musicapp.db';
  static const String _loggedInUserKey = 'logged_in_user_id';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE media(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        filePath TEXT NOT NULL,
        coverArtPath TEXT,
        mediaType TEXT NOT NULL,
        userId INTEGER NOT NULL,
        uploadDate TEXT NOT NULL, -- Added uploadDate column
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites(
        userId INTEGER NOT NULL,
        mediaId INTEGER NOT NULL,
        PRIMARY KEY (userId, mediaId),
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (mediaId) REFERENCES media (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recently_played(
        userId INTEGER NOT NULL,
        mediaId INTEGER NOT NULL,
        playedAt TEXT NOT NULL,
        PRIMARY KEY (userId, mediaId),
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (mediaId) REFERENCES media (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Fetches a list of all media from the database.
  Future<List<Media>> getMedia() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('media');
    return List.generate(maps.length, (i) => Media.fromMap(maps[i]));
  }

  /// Registers a new user.
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final db = await database;
    try {
      await db.insert('users', {
        'username': username,
        'email': email,
        'password': password,
      }, conflictAlgorithm: ConflictAlgorithm.fail);
      return {'error': false, 'message': 'Registration successful'};
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return {'error': true, 'message': 'Username or email already exists.'};
      }
      return {'error': true, 'message': 'An error occurred: $e'};
    }
  }

  /// Logs in a user and stores their ID.
  Future<Map<String, dynamic>> login(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> users = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (users.isNotEmpty) {
      final user = users.first;
      await _storage.write(key: _loggedInUserKey, value: user['id'].toString());
      return {'error': false, 'message': 'Login successful'};
    } else {
      return {'error': true, 'message': 'Invalid username or password'};
    }
  }

  /// Retrieves the stored user ID.
  Future<int?> getLoggedInUserId() async {
    final id = await _storage.read(key: _loggedInUserKey);
    return id != null ? int.tryParse(id) : null;
  }

  /// Deletes the stored user ID upon logout.
  Future<void> logout() async {
    await _storage.delete(key: _loggedInUserKey);
  }

  /// Fetches media uploaded by the currently authenticated user.
  Future<List<Media>> getMyMedia() async {
    final userId = await getLoggedInUserId();
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Media.fromMap(maps[i]));
  }

  /// Gets the username of the currently logged-in user.
  Future<String?> getUsername() async {
    final userId = await getLoggedInUserId();
    if (userId == null) return null;

    final db = await database;
    final List<Map<String, dynamic>> users = await db.query(
      'users',
      columns: ['username'],
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (users.isNotEmpty) {
      return users.first['username'] as String;
    }
    return null;
  }

  /// "Uploads" media by adding it to the database.
  Future<Map<String, dynamic>> uploadMedia(
    String title,
    File mediaFile, {
    File? coverArtFile,
  }) async {
    final userId = await getLoggedInUserId();
    if (userId == null) {
      throw Exception('Not authenticated. Cannot upload.');
    }

    final db = await database;
    final username = await getUsername() ?? 'Unknown Artist';
    final mediaType =
        mediaFile.path.endsWith('mp4') || mediaFile.path.endsWith('mov')
            ? 'video'
            : 'audio';

    try {
      await db.insert('media', {
        'title': title,
        'artist': username,
        'filePath': mediaFile.path, // Store local file path
        'coverArtPath': coverArtFile?.path,
        'mediaType': mediaType,
        'userId': userId,
        'uploadDate':
            DateTime.now()
                .toIso8601String(), // Store current time as ISO 8601 string
      });
      return {'error': false, 'message': 'Upload successful'};
    } catch (e) {
      return {'error': true, 'message': 'Database error: $e'};
    }
  }

  /// Updates an existing media item in the database.
  Future<Map<String, dynamic>> updateMedia(
    int mediaId,
    String title, {
    File? newMediaFile,
    File? newCoverArtFile,
  }) async {
    final userId = await getLoggedInUserId();
    if (userId == null) {
      return {'error': true, 'message': 'Not authenticated.'};
    }

    final db = await database;
    final Map<String, dynamic> dataToUpdate = {'title': title};

    if (newMediaFile != null) {
      dataToUpdate['filePath'] = newMediaFile.path;
      dataToUpdate['mediaType'] =
          newMediaFile.path.endsWith('mp4') || newMediaFile.path.endsWith('mov')
              ? 'video'
              : 'audio';
    }

    if (newCoverArtFile != null) {
      dataToUpdate['coverArtPath'] = newCoverArtFile.path;
    }

    try {
      await db.update(
        'media',
        dataToUpdate,
        where: 'id = ?',
        whereArgs: [mediaId],
      );
      return {'error': false, 'message': 'Update successful'};
    } catch (e) {
      return {'error': true, 'message': 'Database error: $e'};
    }
  }

  /// Deletes a media item from the database.
  Future<void> deleteMedia(int mediaId) async {
    final userId = await getLoggedInUserId();
    if (userId == null) return;

    final db = await database;
    await db.delete(
      'media',
      where: 'id = ? AND userId = ?',
      whereArgs: [mediaId, userId],
    );
  }

  /// Toggles a favorite status for a media item.
  Future<Map<String, dynamic>> toggleFavorite(int mediaId) async {
    final userId = await getLoggedInUserId();
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final db = await database;
    final List<Map<String, dynamic>> existing = await db.query(
      'favorites',
      where: 'userId = ? AND mediaId = ?',
      whereArgs: [userId, mediaId],
    );

    try {
      if (existing.isNotEmpty) {
        // It exists, so remove it
        await db.delete(
          'favorites',
          where: 'userId = ? AND mediaId = ?',
          whereArgs: [userId, mediaId],
        );
        return {'error': false, 'message': 'Removed from favorites'};
      } else {
        // It doesn't exist, so add it
        await db.insert('favorites', {'userId': userId, 'mediaId': mediaId});
        return {'error': false, 'message': 'Added to favorites'};
      }
    } catch (e) {
      return {'error': true, 'message': 'Database error: $e'};
    }
  }

  /// Fetches the user's favorited media.
  Future<List<Media>> getFavorites() async {
    final userId = await getLoggedInUserId();
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT m.* FROM media m
      INNER JOIN favorites f ON m.id = f.mediaId
      WHERE f.userId = ?
    ''',
      [userId],
    );

    return List.generate(maps.length, (i) => Media.fromMap(maps[i]));
  }

  /// Adds a media item to the user's recently played list.
  Future<void> addRecentlyPlayed(int mediaId) async {
    final userId = await getLoggedInUserId();
    if (userId == null) {
      // Can't save for guest users, so we do nothing.
      return;
    }

    final db = await database;
    // Using 'replace' will either insert a new row or update the 'playedAt'
    // timestamp if the media item is already in the list.
    await db.insert('recently_played', {
      'userId': userId,
      'mediaId': mediaId,
      'playedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Fetches the user's recently played media, ordered by most recent.
  Future<List<Media>> getRecentlyPlayed() async {
    final userId = await getLoggedInUserId();
    if (userId == null) {
      // Guests do not have a recently played list.
      return [];
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT m.* FROM media m
      INNER JOIN recently_played rp ON m.id = rp.mediaId
      WHERE rp.userId = ?
      ORDER BY rp.playedAt DESC
    ''',
      [userId],
    );

    return List.generate(maps.length, (i) => Media.fromMap(maps[i]));
  }
}
