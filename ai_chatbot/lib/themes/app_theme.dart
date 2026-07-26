import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF23262F); // Bot Bubble Color
  static const Color limeGreen = Color(0xFFB6FF2E); // User Bubble Color

  static final BoxDecoration gradientBg = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      // Using 'stops' ensures the transition happens exactly in the middle
      colors: [darkBackground, limeGreen],
      stops: [0.3, 0.9], // Adjusting these numbers balances the colors
    ),
  );

  static ThemeData theme = ThemeData(
    scaffoldBackgroundColor: darkBackground,
    brightness: Brightness.dark,
    primaryColor: limeGreen,
  );
}
