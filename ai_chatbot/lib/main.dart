import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this
import 'package:ai_chatbot/screens/login_screen.dart';
import 'package:ai_chatbot/screens/chat_screen.dart';
import 'package:ai_chatbot/screens/onboarding.dart'; // Import your onboarding
import 'themes/app_theme.dart';

void main() async {
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

      // THE NEW TRAFFIC COP LOGIC
      home: StreamBuilder<User?>(
        // 1. Listen to see if a user is logged in
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {

          // If no user is logged in, show the Login Screen
          if (snapshot.data == null) {
            return const LoginScreen();
          }

          // 2. If a user IS logged in, we must check their "Onboarding Tag" in the database
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnap) {
              // While we wait for the database to answer, show a loading spinner
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // Look at the data we got from the database
              if (userSnap.hasData && userSnap.data!.exists) {
                var data = userSnap.data!.data() as Map<String, dynamic>;

                // IF they finished onboarding, take them to Chat
                if (data['hasCompletedOnboarding'] == true) {
                  return const ChatScreen();
                }
              }

              // IF they are new or haven't finished, take them to Onboarding
              return const OnboardingMain();
            },
          );
        },
      ),
    );
  }
}
