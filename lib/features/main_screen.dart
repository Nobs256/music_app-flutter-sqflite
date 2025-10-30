// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:musicapp/features/auth/login_screen.dart';
import 'package:flutter/services.dart';
import 'package:musicapp/data/services/database_service.dart';
import 'package:musicapp/features/home/home_screen.dart';
import 'package:musicapp/features/profile/profile_screen.dart';

import 'player/mini_player.dart';
import 'home/favorites_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  bool _isLoggedIn = false; // Default to not logged in
  DateTime? _lastPressedAt; // to track back button presses

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final userId =
        await _dbService
            .getLoggedInUserId(); // Check for user ID instead of token
    if (mounted) {
      setState(() {
        // Update the state if the user is logged in
        _isLoggedIn = userId != null;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildAuthPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Please log in to see this page.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              _checkLoginStatus(); // Re-check login status after returning
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomeScreen(isLoggedIn: _isLoggedIn),
      _isLoggedIn ? const FavoritesScreen() : _buildAuthPlaceholder(),
      _isLoggedIn ? const ProfileScreen() : _buildAuthPlaceholder(),
    ];

    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
            _lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return false; // Prevent app from exiting
        }
        SystemNavigator.pop(); // Exit the app
        return true;
      },
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              body: IndexedStack(index: _selectedIndex, children: pages),
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite),
                    label: 'Favorites',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
