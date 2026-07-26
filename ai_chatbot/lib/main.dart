// lib/main.dart
import 'package:ai_chatbot/database/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ai_chatbot/screens/login_screen.dart';
import 'themes/app_theme.dart';
import 'package:ai_chatbot/screens/chat_screen.dart';

void main() async {
  // This line ensures Firebase is ready before the app opens
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "NEXA",
      theme: AppTheme.theme,
      // Start with Login Screen
      home: AuthService.instance.currentUserId == ""
      ? const LoginScreen()
      : const ChatScreen(),
    );
  }
}
