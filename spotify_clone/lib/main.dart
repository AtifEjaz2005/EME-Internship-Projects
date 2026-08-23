import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spotify_clone/screens/main_wrapper.dart';
import 'package:spotify_clone/services/auth_service.dart';
import 'backend/firebase_options.dart';
import 'themes/app_colors.dart';
import 'package:spotify_clone/screens/login_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SonicStream());
}

class SonicStream extends StatelessWidget {
  const SonicStream({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sonic Stream',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.primaryBackground,
        fontFamily: 'Plus Jakarta Sans', // Ensure this is in your pubspec.yaml
      ),
      // Inside SonicStream class build method
home: StreamBuilder<User?>(
  stream: AuthService().user,
  builder: (context, snapshot) {
    // If the snapshot has data, the user is logged in
    if (snapshot.hasData) {
      return const MainWrapper(); // Your Home Shell
    } else {
      return const LoginScreen(); // Show Login if not authenticated
    }
  },
),
    );
  }
}
