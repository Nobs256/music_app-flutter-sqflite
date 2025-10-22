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

  static List<Media> fromJsonList(String source) {
    final List<dynamic> jsonList = json.decode(source);
    return jsonList.map((json) => Media.fromJson(json)).toList();
  }
}
