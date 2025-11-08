import 'package:flutter/material.dart';
import 'package:musicapp/data/models/media.dart';
import 'package:musicapp/data/services/api_service.dart';
import 'package:musicapp/features/auth/auth_provider.dart';
import 'package:musicapp/features/player/audio_player_provider.dart';
import 'package:musicapp/features/player/media_player_screen.dart';
import 'package:musicapp/features/profile/upload_screen.dart';
import 'package:musicapp/features/profile/edit_media_screen.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required Null Function() onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  // The future will now return a Map with media and user stats
  late Future<Map<String, dynamic>> _profileDataFuture;

  @override
  void initState() {
    super.initState();
    // Assuming getMyMedia now returns a map like {'media': [...], 'subscriber_count': X}
    _profileDataFuture = _apiService.getMyMedia();
  }

  Future<void> _loadMyMedia() async {
    setState(() {
      _profileDataFuture = _apiService.getMyMedia(forceRefresh: true);
    });
  }

  Future<void> _deleteMedia(Media media) async {
    // Show a confirmation dialog before deleting.
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete "${media.title}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'DELETE',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    // If the user did not confirm, do nothing.
    if (confirmed != true) {
      return;
    }

    try {
      final response = await _apiService.deleteMedia(media.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Media deleted.')),
        );
        // Refresh the list of media.
        _loadMyMedia();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting media: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(authProvider.username ?? 'My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
              // The MainScreen will automatically rebuild to the logged-out state.
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyMedia,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('You have not uploaded any media yet.'),
              );
            }

            final profileData = snapshot.data!;
            final mediaList = (profileData['media'] as List)
                .map((item) => Media.fromJson(item))
                .toList();
            final subscriberCount = profileData['subscriber_count'] ?? 0;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '$subscriberCount Subscribers',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final media = mediaList[index];
                      final likes = media.likesCount ?? 0;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (media.coverArtPath != null &&
                                  media.coverArtPath!.startsWith('http'))
                              ? NetworkImage(media.coverArtPath!)
                              : null,
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
                        subtitle: Row(
                          children: [
                            const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('$likes likes'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit Title',
                              onPressed: () async {
                                final bool? editSuccess =
                                    await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EditMediaScreen(media: media),
                                  ),
                                );
                                if (editSuccess == true) _loadMyMedia();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Delete Media',
                              onPressed: () => _deleteMedia(media),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (media.mediaType == 'audio') {
                            Provider.of<AudioPlayerProvider>(context, listen: false).play(media);
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
                    childCount: mediaList.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to the upload screen and wait for a result.
          final bool? uploadSuccess = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const UploadScreen()));
          // If an upload was successful, refresh the list.
          if (uploadSuccess == true) {
            _loadMyMedia();
          }
        },
        child: const Icon(Icons.upload),
        tooltip: 'Upload Media',
      ),
    );
  }
}
