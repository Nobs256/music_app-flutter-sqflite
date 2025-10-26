import 'dart:convert';

class Media {
  final int id;
  final String title;
  final String artist;
  final String filePath;
  final String? coverArtPath;
  final String mediaType;
  final DateTime uploadDate;

  Media({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    this.coverArtPath,
    required this.mediaType,
    required this.uploadDate,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      filePath: json['file_path'],
      coverArtPath: json['cover_art_path'],
      mediaType: json['media_type'],
      uploadDate: DateTime.parse(json['upload_date']),
    );
  }

  /// Factory constructor to create a Media object from a database map.
  factory Media.fromMap(Map<String, dynamic> map) {
    return Media(
      id: map['id'] as int,
      title: map['title'] as String,
      artist: map['artist'] as String,
      filePath: map['filePath'] as String,
      coverArtPath: map['coverArtPath'] as String?,
      mediaType: map['mediaType'] as String,
      // Parse the stored ISO 8601 string back into a DateTime object
      uploadDate: DateTime.parse(map['uploadDate'] as String),
    );
  }

  static List<Media> fromJsonList(String source) {
    final List<dynamic> jsonList = json.decode(source);
    return jsonList.map((json) => Media.fromJson(json)).toList();
  }
}
