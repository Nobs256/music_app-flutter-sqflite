import 'package:flutter/material.dart';

import 'package:musicapp/data/models/media.dart';
import 'package:musicapp/data/services/api_service.dart';
import 'package:musicapp/features/player/media_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Media>> _mediaFuture;
  final ApiService _apiService = ApiService();

  // State for search functionality
  final TextEditingController _searchController = TextEditingController();
  List<Media> _allMedia = [];
  List<Media> _filteredMedia = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Fetch the media when the screen is first loaded
    _mediaFuture = _apiService.getMedia();
    _mediaFuture.then((mediaList) {
      if (mounted) {
        setState(() {
          _allMedia = mediaList;
          _filteredMedia = mediaList;
        });
      }
    });
    _searchController.addListener(_filterMedia);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterMedia);
    _searchController.dispose();
    super.dispose();
  }

  void _filterMedia() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMedia =
          _allMedia.where((media) {
            final titleMatches = media.title.toLowerCase().contains(query);
            final artistMatches = media.artist.toLowerCase().contains(query);
            return titleMatches || artistMatches;
          }).toList();
    });
  }

  Future<void> _handleRefresh() async {
    // This will re-trigger the FutureBuilder
    setState(() {
      _mediaFuture = _apiService.getMedia(forceRefresh: true);
    });

    // Await the new future and update the local lists for searching
    final mediaList = await _mediaFuture;
    if (mounted) {
      setState(() {
        _allMedia = mediaList;
        _filteredMedia = mediaList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching ? null : const Text('Mbarara Music'),
        actions: [
          // Placeholder for login button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search by title or artist...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: FutureBuilder<List<Media>>(
                future: _mediaFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _allMedia.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError && _allMedia.isEmpty) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}\nPull to try again.',
                      ),
                    );
                  } else if (_allMedia.isEmpty) {
                    return const Center(child: Text('No music found.'));
                  }

                  return ListView.builder(
                    itemCount: _filteredMedia.length,
                    itemBuilder: (context, index) {
                      final media = _filteredMedia[index];
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
          ],
        ),
      ),
    );
  }
}
