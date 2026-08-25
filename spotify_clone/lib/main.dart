import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'backend/firebase_options.dart';
import 'themes/app_colors.dart';
import 'screens/login_screen.dart';
import 'screens/main_wrapper.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SonicStream());
}

class SonicStream extends StatelessWidget {
  const SonicStream({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.primaryBackground,
        fontFamily: 'Plus Jakarta Sans',
      ),
      // PERSISTENCE LOGIC: StreamBuilder listens to Firebase Auth state
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)));
          }
          if (snapshot.hasData) {
            return const MainWrapper(); // Session exists, skip login
          }
          return const LoginScreen(); // No session, show login
        },
      ),
    );
  }
}
