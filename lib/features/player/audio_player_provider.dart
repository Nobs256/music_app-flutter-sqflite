import 'dart:io';
import 'package:flutter/material.dart';
import 'package:musicapp/data/models/media.dart';
import 'package:video_player/video_player.dart';

class AudioPlayerProvider with ChangeNotifier {
  VideoPlayerController? _controller;
  Media? _currentMedia;
  bool _isPlaying = false;

  VideoPlayerController? get controller => _controller;
  Media? get currentMedia => _currentMedia;
  bool get isPlaying => _isPlaying;
  bool get isPlayerActive => _controller != null && _currentMedia != null;

  Future<void> play(Media media) async {
    // If it's the same song and it's paused, just resume.
    if (_currentMedia?.id == media.id && _controller != null && !_isPlaying) {
      await _controller!.play();
      _isPlaying = true;
      notifyListeners();
      return;
    }

    // If a different song is played, or no song is active
    await stop(); // Stop and dispose previous player

    _currentMedia = media;

    if (media.filePath.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(media.filePath));
    } else {
      _controller = VideoPlayerController.file(File(media.filePath));
    }

    try {
      await _controller!.initialize();
      await _controller!.play();
      _isPlaying = true;
      _controller!.addListener(_onPlaybackStateChanged);
      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing audio player: $e");
      await stop();
    }
  }

  void _onPlaybackStateChanged() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final isFinished =
        _controller!.value.position >= _controller!.value.duration;

    // When song finishes, update state to paused
    if (isFinished && _isPlaying) {
      _isPlaying = false;
      // Seek to start so it can be replayed
      _controller?.seekTo(Duration.zero);
      notifyListeners();
    } else if (_isPlaying != _controller!.value.isPlaying) {
      // Sync state if changed from outside
      _isPlaying = _controller!.value.isPlaying;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (_controller != null && _isPlaying) {
      await _controller!.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_controller != null && !_isPlaying) {
      await _controller!.play();
      _isPlaying = true;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (_controller != null) {
      await _controller!.pause();
      _controller!.removeListener(_onPlaybackStateChanged);
      await _controller!.dispose();
      _controller = null;
    }
    _currentMedia = null;
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
