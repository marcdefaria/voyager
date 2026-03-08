import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';
import 'chat_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ChatProvider(),
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
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const ChatScreen(),
    );
  }
}
