import 'package:flutter/material.dart';

class UIConstants {
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color deepBlack = Color(0xFF050505);
  static const Color cardGrey = Color(0xFF151515);
  static const Color surfaceGrey = Color(0xFF1E1E1E);
  static const Color errorRed = Color(0xFFFF5252);

  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 15,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ];

  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
    color: Colors.white,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
    color: Colors.white54,
  );
}
