import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:musicapp/data/services/api_service.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:musicapp/data/services/local_storage_service.dart';
import 'package:musicapp/features/player/audio_player_provider.dart';
import 'package:musicapp/data/models/media.dart';
import 'package:musicapp/features/player/media_player_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  // State and logic passed down from MainScreen
  final Future<void> initialLoadFuture;
  final List<Media> allMedia;
  final Set<int> favoriteMediaIds;
  final Map<int, bool> likeStatus;
  final Map<int, bool> subscriptionStatus;
  final Map<int, double> downloadProgress;
  final List<Media> downloadedMedia;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int mediaId) onToggleFavorite;
  final Future<void> Function(Media media) onToggleLike;
  final Future<void> Function(int artistId) onToggleSubscription;
  final Future<void> Function() onDownloadComplete;

  const HomeScreen({
    super.key,
    required this.isLoggedIn,
    required this.initialLoadFuture,
    required this.allMedia,
    required this.favoriteMediaIds,
    required this.likeStatus,
    required this.subscriptionStatus,
    required this.downloadProgress,
    required this.downloadedMedia,
    required this.onRefresh,
    required this.onToggleFavorite,
    required this.onToggleLike,
    required this.onToggleSubscription,
    required this.onDownloadComplete,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final LocalStorageService _localStorage = LocalStorageService();
  late TabController _tabController;

  // State for search functionality
  final TextEditingController _searchController = TextEditingController();
  List<Media> _filteredVideos = [];
  List<Media> _filteredAudios = [];
  List<Media> _filteredDownloads = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_filterMedia);
    // Set up the download listener once.
    _setupDownloadListener();

    // Initial filter when the widget is first built
    _filterMedia();

    // Add listener to refresh downloads data when tab is switched to
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 2) {
        // When switching to the downloads tab, ensure we have the latest data.
        // This is a good place to call onDownloadComplete to refresh from storage.
        widget.onDownloadComplete();
        // The data is already in widget.downloadedMedia, just need to filter
        _filterMedia();
      }
    });
  }

  void _setupDownloadListener() {
    FileDownloader().updates.listen((update) async {
      // Try to get the media ID from the task's metadata.
      final mediaId = int.tryParse(update.task.metaData as String? ?? '');
      if (mediaId == null) return;

      if (update is TaskProgressUpdate) {
        if (mounted) {
          setState(() => widget.downloadProgress[mediaId] = update.progress);
        }
      } else if (update is TaskStatusUpdate) {
        if (update.status == TaskStatus.complete) {
          if (mounted) {
            // The task object in the update contains the final directory and filename.
            final task = update.task;
            // The `task.filePath()` method gives the full, absolute path to the downloaded file.
            final fullPath = await task.filePath();

            // Persist metadata with the correct local path.
            final media = widget.allMedia.firstWhere((m) => m.id == mediaId);
            await _localStorage.addDownload(media, fullPath);

            await widget.onDownloadComplete();
            setState(() => widget.downloadProgress[mediaId] = 1.0);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Downloaded: ${media.title}')),
            );
          }
        } else if (update.status == TaskStatus.failed ||
            update.status == TaskStatus.canceled) {
          if (mounted) {
            setState(() => widget.downloadProgress.remove(mediaId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download failed.')),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_filterMedia);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the media list from the parent changes, re-filter the results.
    if (widget.allMedia != oldWidget.allMedia ||
        widget.downloadedMedia != oldWidget.downloadedMedia) {
      _filterMedia();
    }
  }

  void _resetSearch() {
    _searchController.clear();
  }

  void _filterMedia() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVideos =
          widget.allMedia
              .where(
                (media) =>
                    media.mediaType == 'video' &&
                    (media.title.toLowerCase().contains(query) ||
                        media.artist.toLowerCase().contains(query)),
              )
              .toList();
      _filteredAudios =
          widget.allMedia
              .where(
                (media) =>
                    media.mediaType == 'audio' &&
                    (media.title.toLowerCase().contains(query) ||
                        media.artist.toLowerCase().contains(query)),
              )
              .toList();
      _filteredDownloads =
          widget.downloadedMedia.where((media) {
            return media.title.toLowerCase().contains(query) ||
                media.artist.toLowerCase().contains(query);
          }).toList();
    });
  }

  Future<void> _toggleFavorite(int mediaId) async {
    if (!widget.isLoggedIn) return;

    // Optimistically update the UI for an instant response.
    widget.onToggleFavorite(mediaId);
  }

  Future<void> _downloadMedia(Media media) async {
    if (!widget.isLoggedIn) return;

    // The flutter_file_downloader package handles permissions automatically.
    setState(() {
      widget.downloadProgress[media.id] = 0.0;
    });

    // The URL for the download is the direct file path from the media object.
    // The provided `download.php` script is for a different download method and is not used here.
    final task = DownloadTask(
      url: media.filePath.trim(),
      filename: media.filePath.split('/').last,
      directory: 'media_downloads', // Use a dedicated sub-folder
      updates: Updates.progress, 
      requiresWiFi: false,
      allowPause: true,
      // Associate the media ID with the task for easy identification in the listener.
      metaData: media.id.toString(),
    );

    // The listener set up in initState will handle all progress and status updates.
    await FileDownloader().enqueue(task);
  }

  Future<void> _toggleLike(Media media) async {
    if (!widget.isLoggedIn) return;

    // Call the function passed down from MainScreen
    widget.onToggleLike(media);
  }

  Future<void> _toggleSubscription(int artistId) async {
    if (!widget.isLoggedIn) return;

    // Call the function passed down from MainScreen
    widget.onToggleSubscription(artistId);
  }

  Widget _buildFavoriteButton(Media media) {
    final isFavorite = widget.favoriteMediaIds.contains(media.id);
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Use a scale transition for a 'popping' effect
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          // Add a key to help AnimatedSwitcher differentiate between the two icons
          key: ValueKey<bool>(isFavorite),
          color: Colors.redAccent,
        ),
      ),
      onPressed: () {
        _toggleFavorite(media.id);
      },
    );
  }

  Widget _buildDownloadButton(Media media) {
    final progress = widget.downloadProgress[media.id];
    final isDownloading = progress != null;

    // When download is complete (progress >= 1.0), show a checkmark briefly.
    if (isDownloading && progress >= 1.0) {
      // After a short delay, remove the item from the progress map.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            widget.downloadProgress.remove(media.id);
          });
        }
      });
      return const IconButton(
        icon: Icon(Icons.check_circle, color: Colors.greenAccent),
        onPressed: null, // Disable button
      );
    }

    // Use a Stack to overlay the progress indicator on the icon.
    return SizedBox(
      width: 48, // Standard IconButton size
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isDownloading)
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.0,
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          IconButton(
            icon: Icon(
              isDownloading ? Icons.close : Icons.download,
              color: isDownloading ? Colors.white : Colors.blueAccent,
            ),
            onPressed:
                () =>
                    isDownloading
                        ? null
                        : _downloadMedia(
                          media,
                        ), // TODO: Implement cancel download
          ),
        ],
      ),
    );
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
                : const Text('Mbarara Music'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                // Clear search when closing the search bar
                if (!_isSearching) _resetSearch();
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'VIDEOS'),
            Tab(text: 'AUDIOS'),
            Tab(text: 'DOWNLOADS'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: FutureBuilder<void>(
          future: widget.initialLoadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                widget.allMedia.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError && widget.allMedia.isEmpty) {
              String errorMessage = 'An error occurred. Please try again';
              bool isOffline = false;
              // Check if the error is a network-related issue from Dio.
              if (snapshot.error is DioException) {
                final dioError = snapshot.error as DioException;
                if (dioError.type == DioExceptionType.connectionError ||
                    dioError.type == DioExceptionType.sendTimeout ||
                    dioError.type == DioExceptionType.receiveTimeout ||
                    dioError.error is SocketException) {
                  isOffline = true;
                  errorMessage = 'Please check your connection and try again.';
                }
              }
              return _buildErrorWidget(errorMessage, isOffline);
            } else if (widget.allMedia.isEmpty) {
              return const Center(child: Text('No media found.'));
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // Videos Tab
                _buildVideosList(),
                // Audios Tab
                _buildAudiosList(),
                // Downloads Tab
                _buildDownloadsList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message, bool isOffline) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 24),
            Text(
              isOffline ? 'You Are Offline' : 'Oops!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('TRY AGAIN'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsList() {
    if (!widget.isLoggedIn) {
      return const Center(child: Text('Log in to see your downloads.'));
    }
    if (_filteredDownloads.isEmpty) {
      return const Center(child: Text('You have no downloaded items.'));
    }

    return ListView.builder(
      itemCount: _filteredDownloads.length,
      itemBuilder: (context, index) {
        final media = _filteredDownloads[index];
        // The filePath from a downloaded media object is the local path.
        final file = File(media.filePath);
        final fileExists = file.existsSync();

        // Check if the cover art is a local file path
        final isCoverArtLocal =
            media.coverArtPath != null &&
            !media.coverArtPath!.startsWith('http');
        final localCoverArtFile =
            isCoverArtLocal ? File(media.coverArtPath!) : null;
        final localCoverArtExists = localCoverArtFile?.existsSync() ?? false;

        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage:
                isCoverArtLocal && localCoverArtExists
                    ? FileImage(localCoverArtFile!) as ImageProvider
                    : (media.coverArtPath != null &&
                            media.coverArtPath!.startsWith('http')
                        ? NetworkImage(media.coverArtPath!)
                        : null),
            child:
                (media.coverArtPath == null ||
                        (isCoverArtLocal && !localCoverArtExists))
                    ? Icon(
                      media.mediaType == 'audio'
                          ? Icons.music_note
                          : Icons.videocam,
                    )
                    : null,
          ),
          title: Text(media.title),
          subtitle: Text(
            fileExists ? 'Downloaded' : 'File not found',
            style: TextStyle(color: fileExists ? Colors.green : Colors.red),
          ),
          trailing:
              fileExists
                  ? null
                  : const Icon(Icons.error_outline, color: Colors.red),
          onTap: () {
            if (!fileExists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File has been moved or deleted.'),
                ),
              );
              return;
            }

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
                              media.coverArtPath!.startsWith('http')
                          ? Image.network(
                            media.coverArtPath!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                            loadingBuilder:
                                (context, child, progress) =>
                                    progress == null
                                        ? child
                                        : const Center(
                                          child: CircularProgressIndicator(),
                                        ),
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
                            media.artist, // Artist Name
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (widget
                              .isLoggedIn) // TODO: Pass subscription status down
                            ElevatedButton(
                              onPressed:
                                  () => _toggleSubscription(media.artistId),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                backgroundColor:
                                    (widget.subscriptionStatus[media
                                                .artistId] ??
                                            false)
                                        ? Colors.grey[700]
                                        : Colors.red,
                              ),
                              child: Text(
                                (widget.subscriptionStatus[media.artistId] ??
                                        false)
                                    ? 'SUBSCRIBED'
                                    : 'SUBSCRIBE',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            // TODO: Pass like status and toggle function down
                            onPressed: () => _toggleLike(media),
                            icon: Icon(
                              (widget.likeStatus[media.id] ?? false)
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_alt_outlined,
                            ),
                            label: Text('${media.likesCount ?? 0}'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (widget.isLoggedIn)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildFavoriteButton(media),
                                _buildDownloadButton(media),
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
                media.coverArtPath != null &&
                        media.coverArtPath!.startsWith('http')
                    ? NetworkImage(media.coverArtPath!)
                    : null,
            onBackgroundImageError: (e, s) => print('Image load error: $e'),
            child:
                media.coverArtPath == null ||
                        !media.coverArtPath!.startsWith('http')
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
                      _buildFavoriteButton(media),
                      _buildDownloadButton(media),
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
}
