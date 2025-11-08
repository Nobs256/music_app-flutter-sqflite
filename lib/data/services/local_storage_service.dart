import 'dart:convert';
import 'package:musicapp/data/models/media.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service for managing client-side data persistence using SharedPreferences.
class LocalStorageService {
  static const _recentsKey = 'recently_played_ids';
  static const _downloadsKey = 'downloaded_media';
  static const _maxRecents = 20;

  /// Adds a media item to the list of recently played items.
  Future<void> addRecent(Media media) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recents = prefs.getStringList(_recentsKey) ?? [];

    // Remove existing entry to move it to the top.
    recents.remove(media.id.toString());
    // Add to the beginning of the list.
    recents.insert(0, media.id.toString());

    // Trim the list if it exceeds the max size.
    if (recents.length > _maxRecents) {
      recents = recents.sublist(0, _maxRecents);
    }

    await prefs.setStringList(_recentsKey, recents);
  }

  /// Retrieves the list of recently played media IDs.
  Future<List<int>> getRecentIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_recentsKey) ?? [];
    return ids.map(int.parse).toList();
  }

  /// Adds a downloaded media item's metadata to local storage.
  Future<void> addDownload(Media media, String localPath) async {
    final prefs = await SharedPreferences.getInstance();
    final downloads = await getDownloads();

    // Create a copy with the local file path for offline playback.
    final localMedia = media.copyWith(filePath: localPath);

    // Remove if it already exists to avoid duplicates.
    downloads.removeWhere((m) => m.id == localMedia.id);
    downloads.add(localMedia);

    // Convert list of Media objects to list of JSON strings.
    final stringList = downloads.map((m) => json.encode(m.toJson())).toList();
    await prefs.setStringList(_downloadsKey, stringList);
  }

  /// Retrieves the list of downloaded media.
  Future<List<Media>> getDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_downloadsKey) ?? [];

    return jsonList
        .map((jsonString) {
          final jsonMap = json.decode(jsonString);
          return Media.fromJson(jsonMap);
        })
        .toList();
  }
}