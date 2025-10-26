import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musicapp/features/player/audio_player_provider.dart';
import 'package:provider/provider.dart';
import 'features/home/splashscreen.dart';

void main() {
  // Ensure that plugin services are initialized before the app starts.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AudioPlayerProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mbrara Grooves',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const StartupView(),
    );
  }
}
