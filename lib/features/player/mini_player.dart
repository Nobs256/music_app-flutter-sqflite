import 'dart:io';
import 'package:flutter/material.dart';
import 'package:musicapp/features/player/audio_player_provider.dart';
import 'package:provider/provider.dart';
import 'full_audio_player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, audioProvider, child) {
        if (!audioProvider.isPlayerActive) {
          return const SizedBox.shrink(); // Don't show anything if no media
        }

        final media = audioProvider.currentMedia!;
        final controller = audioProvider.controller!;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FullAudioPlayerScreen()),
            );
          },
          child: Material(
            elevation: 8.0,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage:
                          media.coverArtPath != null &&
                                  media.coverArtPath!.isNotEmpty
                              ? FileImage(File(media.coverArtPath!))
                              : null,
                      child:
                          media.coverArtPath == null ||
                                  media.coverArtPath!.isEmpty
                              ? const Icon(Icons.music_note)
                              : null,
                    ),
                    title: Text(
                      media.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      media.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            audioProvider.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                          ),
                          iconSize: 32.0,
                          onPressed: () {
                            if (audioProvider.isPlaying) {
                              audioProvider.pause();
                            } else {
                              audioProvider.resume();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => audioProvider.stop(),
                        ),
                      ],
                    ),
                  ),
                  // Progress Bar
                  ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value:
                            (value.isInitialized &&
                                    value.duration.inMilliseconds > 0)
                                ? value.position.inMilliseconds /
                                    value.duration.inMilliseconds
                                : 0.0,
                        minHeight: 2.0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
