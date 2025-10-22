import 'package:flutter/material.dart';
import 'package:musicapp/data/models/media.dart';
import 'package:musicapp/features/auth/login_screen.dart';
import 'package:musicapp/data/services/api_service.dart';
import 'package:musicapp/features/profile/upload_screen.dart';
import 'package:musicapp/features/player/media_player_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Media>> _myMediaFuture;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData({bool forceRefresh = false}) {
    // setState is used here to make the FutureBuilder rebuild with the new future.
    setState(() {
      _myMediaFuture = _apiService.getMyMedia(forceRefresh: forceRefresh);
      _apiService.getUsernameFromToken().then((username) {
        if (mounted) {
          setState(() {
            _username = username;
          });
        }
      });
    });
  }

  Future<void> _navigateAndRefresh() async {
    // Await the result from UploadScreen
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const UploadScreen()));

    // If the result is true, it means an upload was successful, so refresh the data.
    if (result == true) {
      _loadUserData();
    }
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (mounted) {
      // Pop the profile screen to return to the home screen
      // Navigate to a fresh login screen to signify being logged out.
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      // A better approach in a real app would be to use a state management solution to update the MainScreen.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_username ?? 'My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<Media>>(
        future: _myMediaFuture,
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

          final mediaList = snapshot.data!;

          return ListView.builder(
            itemCount: mediaList.length,
            itemBuilder: (context, index) {
              final media = mediaList[index];
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndRefresh,
        tooltip: 'Upload Media',
        child: const Icon(Icons.upload),
      ),
    );
  }
}
