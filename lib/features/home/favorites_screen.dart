import 'package:flutter/material.dart';
import 'package:musicapp/data/models/media.dart';
import 'package:musicapp/features/player/audio_player_provider.dart';
import 'package:musicapp/features/player/media_player_screen.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  final List<Media> allMedia;
  final Set<int> favoriteMediaIds;
  final Function(int) onToggleFavorite;
  // Pass the future from MainScreen to know the loading state.
  final Future<void> initialLoadFuture;

  const FavoritesScreen({
    super.key,
    required this.allMedia,
    required this.favoriteMediaIds,
    required this.onToggleFavorite,
    required this.initialLoadFuture,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        // The refresh action is handled by the parent (MainScreen)
      ),
      body: FutureBuilder<void>(
        future: widget.initialLoadFuture,
        builder: (context, snapshot) {
          // Show a loading indicator while the initial data is being fetched.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Once data is loaded, filter and display the favorites.
          final favoriteMediaList = widget.allMedia
              .where((media) => widget.favoriteMediaIds.contains(media.id))
              .toList();

          if (favoriteMediaList.isEmpty) {
            return const Center(
              child: Text('You have no favorite items yet.'),
            );
          }

          return ListView.builder(
            itemCount: favoriteMediaList.length,
            itemBuilder: (context, index) {
              final media = favoriteMediaList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (media.coverArtPath != null &&
                          media.coverArtPath!.startsWith('http'))
                      ? NetworkImage(media.coverArtPath!)
                      : null,
                  onBackgroundImageError: (exception, stackTrace) {
                    // Error is handled by the child icon
                  },
                  child: (media.coverArtPath == null ||
                          !media.coverArtPath!.startsWith('http'))
                      ? Icon(
                          media.mediaType == 'audio'
                              ? Icons.music_note
                              : Icons.videocam,
                        )
                      : null,
                ),
                title: Text(media.title),
                subtitle: Text(media.artist),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.redAccent),
                  onPressed: () => widget.onToggleFavorite(media.id),
                ),
                onTap: () {
                  if (media.mediaType == 'audio') {
                    Provider.of<AudioPlayerProvider>(context, listen: false)
                        .play(media);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MediaPlayerScreen(media: media),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
