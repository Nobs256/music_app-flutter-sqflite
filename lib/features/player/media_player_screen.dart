import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:musicapp/data/models/media.dart';
import 'package:musicapp/data/services/api_service.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaPlayerScreen extends StatefulWidget {
  final Media media;

  const MediaPlayerScreen({super.key, required this.media});

  @override
  State<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends State<MediaPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.media.filePath),
    );
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
                child: Image.network(
                  widget.media.coverArtPath!,
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

  Future<void> _downloadMedia() async {
    // 1. Check for authentication
    final token = await _apiService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to download.')),
      );
      return;
    }

    // 2. Request storage permission
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required to download files.'),
        ),
      );
      return;
    }

    try {
      // 3. Get the downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Could not find the downloads directory.');
      }
      final fileName = widget.media.filePath.split('/').last;
      final savePath = '${directory.path}/$fileName';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Starting download to ${directory.path}...')),
      );

      // 4. Call the API service to download
      await _apiService.downloadMedia(
        widget.media.id,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // You could update a progress indicator here if you wanted
            // print((received / total * 100).toStringAsFixed(0) + "%");
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download complete! Saved to $savePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${e.toString()}')),
      );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download',
            onPressed: _downloadMedia,
          ),
        ],
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
