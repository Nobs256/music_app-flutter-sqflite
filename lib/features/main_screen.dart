import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:musicapp/data/models/media.dart';
import 'package:musicapp/data/services/api_service.dart';
import 'package:musicapp/data/services/local_storage_service.dart';
import 'package:musicapp/features/auth/auth_provider.dart';
import 'package:musicapp/features/auth/login_screen.dart';
import 'package:musicapp/features/home/favorites_screen.dart';
import 'package:musicapp/features/home/home_screen.dart';
import 'package:musicapp/features/player/mini_player.dart';
import 'package:musicapp/features/profile/profile_screen.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // --- State Lifted from HomeScreen ---
  late Future<void> _initialLoadFuture;
  final ApiService _apiService = ApiService();
  final LocalStorageService _localStorage = LocalStorageService();

  List<Media> _allMedia = [];
  Set<int> _favoriteMediaIds = {};
  Map<int, bool> _likeStatus = {};
  Map<int, bool> _subscriptionStatus = {};
  Map<int, double> _downloadProgress = {};
  List<Media> _downloadedMedia = [];
  // --- End of Lifted State ---

  @override
  void initState() {
    super.initState();
    _initialLoadFuture = _loadInitialData();
  }

  bool get _isLoggedIn =>
      Provider.of<AuthProvider>(context, listen: false).isLoggedIn;

  // --- Logic Lifted from HomeScreen ---

  Future<void> _loadInitialData() async {
    final results = await Future.wait<List<dynamic>>([
      _apiService.getMedia(),
      if (_isLoggedIn) _apiService.getFavorites() else Future.value([]),
      if (_isLoggedIn) _localStorage.getDownloads() else Future.value([]),
    ]);

    if (mounted) {
      setState(() {
        _allMedia = (results[0]).cast<Media>();
        final favorites = (results[1]).cast<Media>();
        final downloads = (results[2]).cast<Media>();

        _favoriteMediaIds = favorites.map((media) => media.id).toSet();
        _downloadedMedia = downloads;

        if (_isLoggedIn) {
          for (var media in _allMedia) {
            _likeStatus[media.id] = media.hasLiked ?? false;
            _subscriptionStatus[media.artistId] = media.isSubscribed ?? false;
          }
        }
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _initialLoadFuture = _loadInitialData();
    });
  }

  Future<void> _toggleFavorite(int mediaId) async {
    if (!_isLoggedIn) return;

    final isCurrentlyFavorite = _favoriteMediaIds.contains(mediaId);
    setState(() {
      if (isCurrentlyFavorite) {
        _favoriteMediaIds.remove(mediaId);
      } else {
        _favoriteMediaIds.add(mediaId);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCurrentlyFavorite ? 'Removed from favorites' : 'Added to favorites',
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final response = await _apiService.toggleFavorite(mediaId);
      // If the API call reports an error, revert the optimistic UI update.
      if (response['error'] == true) {
        throw Exception(
          response['message'] ?? 'Failed to update favorites on server.',
        );
      }
      // If successful, the optimistic UI update was correct. No more changes needed.
    } catch (e) {
      print('Error toggling favorite: $e');
      // If any error occurs (network, API error, etc.), revert the UI change.
      if (mounted) {
        setState(() {
          if (isCurrentlyFavorite) {
            _favoriteMediaIds.add(mediaId); // Add it back
          } else {
            _favoriteMediaIds.remove(mediaId); // Remove it
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not update favorites.')),
        );
      }
    }
  }

  Future<void> _toggleLike(Media media) async {
    if (!_isLoggedIn) return;

    final mediaId = media.id;
    final wasLiked = _likeStatus[mediaId] ?? false;
    final originalLikesCount = media.likesCount ?? 0;

    // Optimistic UI update
    setState(() {
      _likeStatus[mediaId] = !wasLiked;
      // Find the media in the main list and update its count
      try {
        final mediaInList = _allMedia.firstWhere((m) => m.id == mediaId);
        mediaInList.likesCount =
            wasLiked ? originalLikesCount - 1 : originalLikesCount + 1;
      } catch (e) {
        // Media might not be in the list, ignore.
      }
    });

    try {
      final response = await _apiService.toggleLike(mediaId);
      if (response['error'] == true) {
        throw Exception(response['message'] ?? 'API error');
      }
    } catch (e) {
      print('Error toggling like: $e');
      // Revert on error
      setState(() {
        _likeStatus[mediaId] = wasLiked;
        try {
          final mediaInList = _allMedia.firstWhere((m) => m.id == mediaId);
          mediaInList.likesCount = originalLikesCount;
        } catch (e) {
          // Media might not be in the list, ignore.
        }
      });
    }
  }

  Future<void> _toggleSubscription(int artistId) async {
    if (!_isLoggedIn) return;

    final wasSubscribed = _subscriptionStatus[artistId] ?? false;

    // Optimistic UI update
    setState(() {
      _subscriptionStatus[artistId] = !wasSubscribed;
    });

    try {
      await _apiService.toggleSubscription(artistId);
    } catch (e) {
      print('Error toggling subscription: $e');
      // Revert on error
      setState(() => _subscriptionStatus[artistId] = wasSubscribed);
    }
  }

  Future<void> _onDownloadComplete() async {
    // This function is called from HomeScreen when a download finishes.
    // It reloads the list of downloaded media from local storage.
    final downloads = await _localStorage.getDownloads();
    if (mounted) {
      setState(() => _downloadedMedia = downloads);
    }
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                'Login Required',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please log in to access this feature.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                child: const Text('GO TO LOGIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --- End of Lifted Logic ---

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // We now build the list of screens here, passing the state down.
    final List<Widget> screens = [
      // Pass all the state and functions to HomeScreen
      HomeScreen(
        key: const PageStorageKey('homeScreen'), // Preserve scroll position
        isLoggedIn: authProvider.isLoggedIn,
        initialLoadFuture: _initialLoadFuture,
        allMedia: _allMedia,
        favoriteMediaIds: _favoriteMediaIds,
        likeStatus: _likeStatus,
        subscriptionStatus: _subscriptionStatus,
        downloadProgress: _downloadProgress,
        downloadedMedia: _downloadedMedia,
        onRefresh: _handleRefresh,
        onToggleFavorite: _toggleFavorite,
        onToggleLike: _toggleLike,
        onToggleSubscription: _toggleSubscription,
        onDownloadComplete: _onDownloadComplete,
      ),
      authProvider.isLoggedIn
          ? FavoritesScreen(
            key: const PageStorageKey('favoritesScreen'),
            allMedia: _allMedia,
            favoriteMediaIds: _favoriteMediaIds,
            onToggleFavorite: _toggleFavorite,
            initialLoadFuture: _initialLoadFuture,
          )
          : _buildLoginPrompt(),
      authProvider.isLoggedIn
          ? ProfileScreen(
            key: const PageStorageKey('profileScreen'),
            onLogout: () {
              setState(() => _selectedIndex = 0);
              _handleRefresh();
            },
          )
          : _buildLoginPrompt(),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            // Use an IndexedStack to keep the state of each tab alive
            child: IndexedStack(index: _selectedIndex, children: screens),
          ),
          // Persistent MiniPlayer at the bottom
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
