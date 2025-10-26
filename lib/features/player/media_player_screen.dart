import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:musicapp/data/models/media.dart';
import 'package:video_player/video_player.dart';

class MediaPlayerScreen extends StatefulWidget {
  final Media media;

  const MediaPlayerScreen({super.key, required this.media});

  @override
  State<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends State<MediaPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.media.filePath.startsWith('http')) {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.media.filePath),
      );
    } else {
      _videoPlayerController = VideoPlayerController.file(
        File(widget.media.filePath),
      );
    }
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      // For audio, show a placeholder with cover art.
      // For video, the player will handle it.
      placeholder:
          widget.media.mediaType == 'audio' && widget.media.coverArtPath != null
              ? Center(
                // Playing from file path
                child: Image.file(
                  File(widget.media.coverArtPath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
              : const Center(child: CircularProgressIndicator()),
      // Show video aspect ratio if it's a video file
      aspectRatio:
          widget.media.mediaType == 'video'
              ? _videoPlayerController.value.aspectRatio
              : null,
    );

    // Refresh the UI once the controller is ready
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.media.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized)
            Expanded(child: Chewie(controller: _chewieController!))
          else
            const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
