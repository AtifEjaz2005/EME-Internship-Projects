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
import 'services/player_service.dart'; // IMPORTED
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Audio Handler
  audioHandler = await AudioService.init(
    builder: () => MusikiAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.musiki.channel.audio',
      androidNotificationChannelName: 'Musiki Music Playback',
      androidNotificationOngoing: true,
      notificationColor: Color(0xFF121414),
    ),
  );

  // RESTORE PREVIOUS SONG & PROGRESS BEFORE RENDERING UI
  await PlayerService().restoreLastSession();

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
        primaryColor: AppColors.primaryGreen,

        // --- GLOBAL PREMIUM SNACKBAR THEME ---
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF222326), // Charcoal card background
          contentTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Plus Jakarta Sans',
          ),
          behavior: SnackBarBehavior.floating, // Floats like a modern pill
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white12, width: 0.8),
          ),
          // Floats above the custom floating bottom nav bar & mini player
          insetPadding: const EdgeInsets.only(bottom: 95, left: 16, right: 16),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            );
          }
          if (snapshot.hasData) {
            return const MainWrapper();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
