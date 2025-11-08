import 'package:flutter/material.dart';
import 'package:musicapp/features/auth/auth_provider.dart';
import 'package:musicapp/features/player/audio_player_provider.dart';
import 'package:provider/provider.dart';

import 'features/home/splashscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the app with MultiProvider to make our providers available globally.
    return MultiProvider(
      providers: [
        // Provider for managing authentication state.
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Provider for managing the audio player state.
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
      ],
      child: MaterialApp(
        title: 'MusicApp',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.grey[900],
          appBarTheme: AppBarTheme(color: Colors.grey[850], elevation: 4),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.grey[850],
            selectedItemColor: Colors.tealAccent,
            unselectedItemColor: Colors.grey[400],
          ),
        ),
        home: const StartupView(),
      ),
    );
  }
}
