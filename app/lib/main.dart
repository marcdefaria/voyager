import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'trips_provider.dart';
import 'trips_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TripsProvider(),
      child: const VoyagerApp(),
    ),
  );
}

class VoyagerApp extends StatelessWidget {
  const VoyagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voyager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const TripsScreen(),
    );
  }
}
