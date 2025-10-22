import 'package:flutter/material.dart';
import 'package:musicapp/data/models/media.dart';
import 'package:musicapp/data/services/api_service.dart';
import 'package:musicapp/features/player/media_player_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Media>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = _apiService.getFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: RefreshIndicator(
        onRefresh: () async => _loadFavorites(),
        child: FutureBuilder<List<Media>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('You have no favorite items yet.'),
              );
            }

            final mediaList = snapshot.data!;

            return ListView.builder(
              itemCount: mediaList.length,
              itemBuilder: (context, index) {
                final media = mediaList[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        (media.coverArtPath != null &&
                                media.coverArtPath!.isNotEmpty)
                            ? NetworkImage(media.coverArtPath!)
                            : null,
                    child:
                        (media.coverArtPath == null ||
                                media.coverArtPath!.isEmpty)
                            ? Icon(
                              media.mediaType == 'audio'
                                  ? Icons.music_note
                                  : Icons.videocam,
                            )
                            : null,
                  ),
                  title: Text(media.title),
                  subtitle: Text(media.artist),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MediaPlayerScreen(media: media),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
