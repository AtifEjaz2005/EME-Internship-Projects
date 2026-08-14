import 'package:flutter/material.dart';

class AppTheme {
  // New Hex Colors
  static const Color darkBackground = Color(0xFF161717);
  static const Color limeGreen = Color(0xFFB6FF2E);
  static const Color botBubble = Color(0xFF242526);

  static final BoxDecoration backgroundDecoration = const BoxDecoration(
    color: darkBackground, // Solid background as requested
  );

  static ThemeData theme = ThemeData(
    scaffoldBackgroundColor: darkBackground,
    brightness: Brightness.dark,
    primaryColor: limeGreen,
    secondaryHeaderColor: botBubble,
  );
}
