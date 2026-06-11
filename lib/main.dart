// lib/main.dart
import 'package:flutter/material.dart';

import 'views/auth/welcome_screen.dart';
import 'views/capsules/capsules_screen.dart';
import 'views/chat/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FenixApp());
}

class FenixApp extends StatelessWidget {
  const FenixApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fénix Pocket OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF4C8CFA),
        scaffoldBackgroundColor: const Color(0xFF13131A),
        fontFamily: 'SF Pro',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/capsules': (context) => const CapsulesScreen(),
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}
