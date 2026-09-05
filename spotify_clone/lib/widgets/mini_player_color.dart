import 'dart:math';
import 'package:flutter/material.dart';

class MiniPlayerColor {
  // Your specific hex codes
  static final List<Color> _palette = [
    const Color(0xFF64030C),
    const Color(0xFF602C28),
    const Color(0xFF01081F),
    const Color(0xFF25040A),
    const Color(0xFF18306D),
    const Color(0xFF306C53),
    const Color(0xFF1C2014),
  ];

  // This returns a random color from the list above
  static Color getNewColor() {
    return _palette[Random().nextInt(_palette.length)];
  }
}
