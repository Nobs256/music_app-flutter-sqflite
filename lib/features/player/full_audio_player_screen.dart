import 'dart:io';
import 'package:flutter/material.dart';
import 'package:musicapp/features/player/audio_player_provider.dart';
import 'package:provider/provider.dart';

class FullAudioPlayerScreen extends StatelessWidget {
  const FullAudioPlayerScreen({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final media = audioProvider.currentMedia;
    final controller = audioProvider.controller;

    if (media == null || controller == null) {
      // This should ideally not happen if we navigate correctly
      return const Scaffold(body: Center(child: Text('No active song.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cover Art
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image:
                      media.coverArtPath != null &&
                              media.coverArtPath!.isNotEmpty
                          ? DecorationImage(
                            image: FileImage(File(media.coverArtPath!)),
                            fit: BoxFit.cover,
                          )
                          : null,
                  color: Colors.grey[800],
                ),
                child:
                    media.coverArtPath == null || media.coverArtPath!.isEmpty
                        ? const Center(
                          child: Icon(
                            Icons.music_note,
                            size: 100,
                            color: Colors.white54,
                          ),
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 32),

            // Title and Artist
            Text(
              media.title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              media.artist,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Seek Bar and Duration
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, child) {
                final position = value.position;
                final duration = value.duration;
                return Column(
                  children: [
                    Slider(
                      value:
                          (position.inMilliseconds > 0 &&
                                  position.inMilliseconds <
                                      duration.inMilliseconds)
                              ? position.inMilliseconds.toDouble()
                              : 0.0,
                      min: 0.0,
                      max: duration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        controller.seekTo(
                          Duration(milliseconds: value.toInt()),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Playback Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // In a real app, you'd have previous/next track logic here
                const IconButton(
                  icon: Icon(Icons.skip_previous),
                  iconSize: 40.0,
                  onPressed: null, // Disabled for now
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: Icon(
                    audioProvider.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  iconSize: 70.0,
                  onPressed: () {
                    if (audioProvider.isPlaying) {
                      audioProvider.pause();
                    } else {
                      audioProvider.resume();
                    }
                  },
                ),
                const SizedBox(width: 24),
                const IconButton(
                  icon: Icon(Icons.skip_next),
                  iconSize: 40.0,
                  onPressed: null, // Disabled for now
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
