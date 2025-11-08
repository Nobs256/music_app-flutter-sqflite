import 'dart:convert';

class Media {
  final int id;
  final String title;
  final int artistId;
  final String artist;
  final String filePath;
  final String? coverArtPath;
  final String mediaType;
  final DateTime uploadDate;
  // Fields for likes and subscriptions
  int? likesCount;
  final bool? hasLiked;
  final bool? isSubscribed;

  Media({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artist,
    required this.filePath,
    this.coverArtPath,
    required this.mediaType,
    required this.uploadDate,
    this.likesCount,
    this.hasLiked,
    this.isSubscribed,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'],
      title: json['title'],
      artistId: json['artist_id'],
      artist: json['artist'],
      filePath: json['file_path'],
      coverArtPath: json['cover_art_path'],
      mediaType: json['media_type'],
      uploadDate: DateTime.parse(json['upload_date']),
      likesCount: json['likes_count'],
      hasLiked: json['has_liked'],
      isSubscribed: json['is_subscribed'],
    );
  }

  static List<Media> fromJsonList(String source) {
    final List<dynamic> jsonList = json.decode(source);
    return jsonList.map((json) => Media.fromJson(json)).toList();
  }

  /// Converts this Media object into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist_id': artistId,
      'artist': artist,
      'file_path': filePath,
      'cover_art_path': coverArtPath,
      'media_type': mediaType,
      'upload_date': uploadDate.toIso8601String(),
      'likes_count': likesCount,
      'has_liked': hasLiked,
      'is_subscribed': isSubscribed,
    };
  }

  /// Creates a new Media instance with updated values.
  Media copyWith({
    int? id,
    String? title,
    int? artistId,
    String? artist,
    String? filePath,
    String? coverArtPath,
    String? mediaType,
    DateTime? uploadDate,
    int? likesCount,
    bool? hasLiked,
    bool? isSubscribed,
  }) {
    return Media(
      id: id ?? this.id,
      title: title ?? this.title,
      artistId: artistId ?? this.artistId,
      artist: artist ?? this.artist,
      filePath: filePath ?? this.filePath,
      coverArtPath: coverArtPath ?? this.coverArtPath,
      mediaType: mediaType ?? this.mediaType,
      uploadDate: uploadDate ?? this.uploadDate,
      likesCount: likesCount ?? this.likesCount,
      hasLiked: hasLiked ?? this.hasLiked,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}
