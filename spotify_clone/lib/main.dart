import 'package:audio_service/audio_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'backend/firebase_options.dart';
import 'themes/app_colors.dart';
import 'screens/login_screen.dart';
import 'screens/main_wrapper.dart';
import 'services/auth_service.dart';
import 'services/audio_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  audioHandler = await AudioService.init(
    builder: () => MusikiAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.musiki.channel.audio',
      androidNotificationChannelName: 'Musiki Music Playback',
      androidNotificationOngoing: true,
      notificationColor: Color(0xFF121414),
    ),
  );

  runApp(const MusikiApp());
}

class MusikiApp extends StatelessWidget {
  const MusikiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MUSIKI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.primaryBackground,
        fontFamily: 'Plus Jakarta Sans',
        // Ensuring primary theme color is consistent
        primaryColor: AppColors.primaryGreen,
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          // If checking for session
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryGreen)));
          }
          // If session exists, go to Main Shell
          if (snapshot.hasData) {
            return const MainWrapper();
          }
          // If no session, go to Login
          return const LoginScreen();
        },
      ),
    );
  }
}
