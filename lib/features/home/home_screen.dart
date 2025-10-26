import 'dart:io';
import 'package:flutter/material.dart';
import 'package:musicapp/features/player/audio_player_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:musicapp/data/models/media.dart';
import 'package:musicapp/data/services/database_service.dart';
import 'package:musicapp/features/player/media_player_screen.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  const HomeScreen({super.key, required this.isLoggedIn});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<void> _initialLoadFuture;
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;

  // State for search functionality
  final TextEditingController _searchController = TextEditingController();
  List<Media> _allMedia = [];
  List<Media> _filteredVideos = [];
  List<Media> _filteredAudios = [];
  List<Media> _recentlyPlayed = [];
  List<Media> _filteredRecentlyPlayed = [];
  Set<int> _favoriteMediaIds = {};
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initialLoadFuture = _loadInitialData();
    _searchController.addListener(_filterMedia);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_filterMedia);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // Use Future.wait to fetch all necessary data in parallel.
    // This ensures that both media and favorites are loaded before the UI tries to build.
    final results = await Future.wait([
      _dbService.getMedia(),
      if (widget.isLoggedIn) _dbService.getFavorites() else Future.value([]),
      if (widget.isLoggedIn)
        _dbService.getRecentlyPlayed()
      else
        Future.value([]),
    ]);

    if (mounted) {
      _allMedia = results[0] as List<Media>;
      final favorites = results[1] as List<Media>;
      _favoriteMediaIds = favorites.map((media) => media.id!).toSet();
      _recentlyPlayed = results[2] as List<Media>;

      _filterMedia(); // Apply initial filtering
    }
  }

  Future<void> _loadFavorites() async {
    // Only load favorites if the user is logged in, based on the passed property.
    if (widget.isLoggedIn) {
      final favorites = await _dbService.getFavorites();
      if (mounted) {
        setState(
          () => _favoriteMediaIds = favorites.map((media) => media.id!).toSet(),
        );
      }
    }
  }

  void _filterMedia() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVideos =
          _allMedia.where((media) {
            final titleMatches = media.title.toLowerCase().contains(query);
            final artistMatches = media.artist.toLowerCase().contains(query);
            return media.mediaType == 'video' &&
                (titleMatches || artistMatches);
          }).toList();

      _filteredAudios =
          _allMedia.where((media) {
            final titleMatches = media.title.toLowerCase().contains(query);
            final artistMatches = media.artist.toLowerCase().contains(query);
            return media.mediaType == 'audio' &&
                (titleMatches || artistMatches);
          }).toList();

      // Only filter recently played if the user is logged in and there are items.
      if (widget.isLoggedIn) {
        _filteredRecentlyPlayed =
            _recentlyPlayed.where((media) {
              final titleMatches = media.title.toLowerCase().contains(query);
              final artistMatches = media.artist.toLowerCase().contains(query);
              return titleMatches || artistMatches;
            }).toList();
      } else {
        // If not logged in, the list should be empty.
        _filteredRecentlyPlayed = [];
      }
    });
  }

  Future<void> _handleRefresh() async {
    // This will re-trigger the FutureBuilder
    await _loadInitialData();
    // The FutureBuilder will not rebuild on its own with setState,
    // but the internal state (_allMedia, etc.) is now fresh.
    if (mounted) {
      setState(() {
        _filterMedia(); // Re-apply search filter or reset lists
      });
    }
  }

  Future<void> _toggleFavorite(int mediaId) async {
    await _dbService.toggleFavorite(mediaId);
    // Show feedback and update the UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _favoriteMediaIds.contains(mediaId)
              ? 'Removed from favorites'
              : 'Added to favorites',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
    _loadFavorites(); // Reload favorites to update the icon
  }

  Future<void> _downloadMedia(Media media) async {
    // 1. Check for permissions
    // On Android 13+ (API 33+), we need to request granular media permissions.
    // On older versions, Permission.storage is used. The permission_handler
    // package gracefully handles requesting a permission that doesn't exist
    // on an older OS version, so we can request all relevant ones.
    Map<Permission, PermissionStatus> statuses;
    if (media.mediaType == 'video') {
      statuses = await [Permission.storage, Permission.videos].request();
    } else {
      // Default to audio permission for audio files or any other type
      statuses = await [Permission.storage, Permission.audio].request();
    }

    // Check if either storage (for older Android) or the specific media
    // permission (for newer Android) is granted.
    final isGranted =
        statuses[Permission.storage] == PermissionStatus.granted ||
        statuses[Permission.videos] == PermissionStatus.granted ||
        statuses[Permission.audio] == PermissionStatus.granted;

    var status = await Permission.storage.request();
    if (!status.isGranted) {
      if (!isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to download files.'),
          ),
        );
        return;
      }
    }

    try {
      // 2. Get the downloads directory
      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory == null) {
        throw Exception('Could not find the downloads directory.');
      }

      // 3. Create the destination path
      final sourceFile = File(media.filePath);
      final fileName = p.basename(media.filePath);
      final destinationPath = p.join(downloadsDirectory.path, fileName);

      // 4. Copy the file
      await sourceFile.copy(destinationPath);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Downloaded to $destinationPath')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                )
                : const Text('Mbrara Grooves'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                // Clear search when closing the search bar
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'RECENT'),
            Tab(text: 'VIDEOS'),
            Tab(text: 'AUDIOS'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: FutureBuilder<void>(
          future: _initialLoadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _allMedia.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError && _allMedia.isEmpty) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}\nPull to try again.',
                  textAlign: TextAlign.center,
                ),
              );
            } else if (_allMedia.isEmpty) {
              return const Center(child: Text('No media found.'));
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // Recently Played Tab
                _buildRecentlyPlayedList(),
                // Videos Tab
                _buildVideosList(),
                // Audios Tab
                _buildAudiosList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideosList() {
    if (_filteredVideos.isEmpty) {
      return const Center(child: Text('No videos found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredVideos.length,
      itemBuilder: (context, index) {
        final media = _filteredVideos[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MediaPlayerScreen(media: media),
              ),
            );
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child:
                      media.coverArtPath != null &&
                              media.coverArtPath!.isNotEmpty
                          ? Image.file(
                            File(media.coverArtPath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                          : Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(
                                Icons.videocam,
                                size: 50,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            media.artist,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (widget.isLoggedIn)
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _favoriteMediaIds.contains(media.id)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _toggleFavorite(media.id!),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.download,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed: () => _downloadMedia(media),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudiosList() {
    if (_filteredAudios.isEmpty) {
      return const Center(child: Text('No audios found.'));
    }
    return ListView.builder(
      itemCount: _filteredAudios.length,
      itemBuilder: (context, index) {
        final media = _filteredAudios[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage:
                media.coverArtPath != null && media.coverArtPath!.isNotEmpty
                    ? FileImage(File(media.coverArtPath!))
                    : null,
            child:
                media.coverArtPath == null || media.coverArtPath!.isEmpty
                    ? const Icon(Icons.music_note)
                    : null,
          ),
          title: Text(media.title),
          subtitle: Text(media.artist),
          trailing:
              widget.isLoggedIn
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _favoriteMediaIds.contains(media.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _toggleFavorite(media.id!),
                        tooltip: 'Favorite',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.download,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () => _downloadMedia(media),
                        tooltip: 'Download',
                      ),
                    ],
                  )
                  : null,
          onTap: () {
            // Use the provider to play audio
            Provider.of<AudioPlayerProvider>(
              context,
              listen: false,
            ).play(media);
          },
        );
      },
    );
  }

  Widget _buildRecentlyPlayedList() {
    if (!widget.isLoggedIn) {
      return const Center(
        child: Text('Log in to see your recently played items.'),
      );
    }
    if (_filteredRecentlyPlayed.isEmpty) {
      return const Center(child: Text('No recently played items.'));
    }

    return ListView.builder(
      itemCount: _filteredRecentlyPlayed.length,
      itemBuilder: (context, index) {
        final media = _filteredRecentlyPlayed[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage:
                media.coverArtPath != null && media.coverArtPath!.isNotEmpty
                    ? FileImage(File(media.coverArtPath!))
                    : null,
            child:
                media.coverArtPath == null || media.coverArtPath!.isEmpty
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
            icon: Icon(
              _favoriteMediaIds.contains(media.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: Colors.redAccent,
            ),
            onPressed: () => _toggleFavorite(media.id!),
            tooltip: 'Favorite',
          ),
          onTap: () {
            if (media.mediaType == 'audio') {
              Provider.of<AudioPlayerProvider>(
                context,
                listen: false,
              ).play(media);
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
  }
}






// import 'dart:io';
// import 'package:flutter/material.dart';

// import 'package:musicapp/data/models/media.dart';
// import 'package:musicapp/data/services/database_service.dart';
// import 'package:musicapp/features/player/media_player_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen>
//     with SingleTickerProviderStateMixin {
//   late Future<List<Media>> _mediaFuture;
//   final DatabaseService _dbService = DatabaseService();
//   late TabController _tabController;

//   // State for search functionality
//   final TextEditingController _searchController = TextEditingController();
//   List<Media> _allMedia = [];
//   List<Media> _filteredVideos = [];
//   List<Media> _filteredAudios = [];
//   bool _isSearching = false;

//   @override
//   void initState() {
//     super.initState();
//     // Fetch the media when the screen is first loaded
//     _mediaFuture = _dbService.getMedia();
//     _tabController = TabController(length: 2, vsync: this);

//     _mediaFuture.then((mediaList) {
//       if (mounted) {
//         setState(() {
//           _allMedia = mediaList;
//           _filteredVideos =
//               _allMedia.where((m) => m.mediaType == 'video').toList();
//           _filteredAudios =
//               _allMedia.where((m) => m.mediaType == 'audio').toList();
//         });
//       }
//     });
//     _searchController.addListener(_filterMedia);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _searchController.removeListener(_filterMedia);
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _filterMedia() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredVideos =
//           _allMedia.where((media) {
//             final titleMatches = media.title.toLowerCase().contains(query);
//             final artistMatches = media.artist.toLowerCase().contains(query);
//             return media.mediaType == 'video' &&
//                 (titleMatches || artistMatches);
//           }).toList();

//       _filteredAudios =
//           _allMedia.where((media) {
//             final titleMatches = media.title.toLowerCase().contains(query);
//             final artistMatches = media.artist.toLowerCase().contains(query);
//             return media.mediaType == 'audio' &&
//                 (titleMatches || artistMatches);
//           }).toList();
//     });
//   }

//   Future<void> _handleRefresh() async {
//     // This will re-trigger the FutureBuilder
//     setState(() {
//       _mediaFuture = _dbService.getMedia();
//     });

//     // Await the new future and update the local lists for searching
//     final mediaList = await _mediaFuture;
//     if (mounted) {
//       setState(() {
//         _allMedia = mediaList;
//         _filterMedia(); // Re-apply search filter or reset lists
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title:
//             _isSearching
//                 ? TextField(
//                   controller: _searchController,
//                   autofocus: true,
//                   decoration: const InputDecoration(
//                     hintText: 'Search by title or artist...',
//                     border: InputBorder.none,
//                   ),
//                   style: const TextStyle(color: Colors.white, fontSize: 18),
//                 )
//                 : const Text('Mbarara Music'),
//         actions: [
//           // Placeholder for login button
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () {
//               setState(() {
//                 _isSearching = !_isSearching;
//                 if (!_isSearching) {
//                   _searchController.clear();
//                 }
//               });
//             },
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _handleRefresh,
//         child: Column(
//           children: [
//             if (_isSearching)
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: TextField(
//                   controller: _searchController,
//                   autofocus: true,
//                   decoration: InputDecoration(
//                     hintText: 'Search by title or artist...',
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     suffixIcon: IconButton(
//                       icon: const Icon(Icons.clear),
//                       onPressed: () => _searchController.clear(),
//                     ),
//                   ),
//                 ),
//               ),
//             Expanded(
//               child: FutureBuilder<List<Media>>(
//                 future: _mediaFuture,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting &&
//                       _allMedia.isEmpty) {
//                     return const Center(child: CircularProgressIndicator());
//                   } else if (snapshot.hasError && _allMedia.isEmpty) {
//                     return Center(
//                       child: Text(
//                         'Error: ${snapshot.error}\nPull to try again.',
//                       ),
//                     );
//                   } else if (_allMedia.isEmpty) {
//                     return const Center(child: Text('No music found.'));
//                   }

//                   return GridView.builder(
//                     padding: const EdgeInsets.all(8.0),
//                     gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 2, // Two items per row
//                           crossAxisSpacing: 8.0,
//                           mainAxisSpacing: 8.0,
//                           childAspectRatio:
//                               0.75, // Adjust as needed for better look
//                         ),
//                     itemCount: _filteredMedia.length,
//                     itemBuilder: (context, index) {
//                       final media = _filteredMedia[index];
//                       return GestureDetector(
//                         onTap: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (_) => MediaPlayerScreen(media: media),
//                             ),
//                           );
//                         },
//                         child: Card(
//                           elevation: 4.0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8.0),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Expanded(
//                                 child: ClipRRect(
//                                   borderRadius: const BorderRadius.vertical(
//                                     top: Radius.circular(8.0),
//                                   ),
//                                   child:
//                                       media.coverArtPath != null &&
//                                               media.coverArtPath!.isNotEmpty
//                                           ? Image.file(
//                                             File(media.coverArtPath!),
//                                             fit: BoxFit.cover,
//                                             width: double.infinity,
//                                           )
//                                           : Center(
//                                             child: Icon(
//                                               media.mediaType == 'audio'
//                                                   ? Icons.music_note
//                                                   : Icons.videocam,
//                                               size: 48.0,
//                                               color: Colors.grey[400],
//                                             ),
//                                           ),
//                                 ),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       media.title,
//                                       style:
//                                           Theme.of(
//                                             context,
//                                           ).textTheme.titleSmall,
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                     Text(
//                                       media.artist,
//                                       style:
//                                           Theme.of(context).textTheme.bodySmall,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }