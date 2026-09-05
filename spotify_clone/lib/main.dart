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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // MAKE SURE 'audioHandler =' IS PRESENT AND AWAITED
  audioHandler = await AudioService.init(
    builder: () => MusikiAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.musiki.channel.audio',
      androidNotificationChannelName: 'Musiki Music Playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(const MusikiApp());
}

class MusikiApp extends StatelessWidget { // Changed name
  const MusikiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MUSIKI', // Changed name
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.primaryBackground,
        fontFamily: 'Plus Jakarta Sans',
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryGreen)));
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
