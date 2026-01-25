import 'package:flutter/material.dart';

/// App color palette
abstract class AppColors {
  // Gameplay colors
  static const stationary = Colors.black;
  static const gettingCloser = Color(0xFFD32F2F); // Red
  static const gettingFarther = Color(0xFF1976D2); // Blue
  static const won = Color(0xFF388E3C); // Green

  // Brand colors
  static const primary = Color(0xFF6750A4);
  static const secondary = Color(0xFF625B71);
  static const tertiary = Color(0xFF7D5260);

  // Semantic colors
  static const error = Color(0xFFB3261E);
  static const success = Color(0xFF388E3C);
  static const warning = Color(0xFFF9A825);

  // Neutral colors
  static const surface = Color(0xFFFFFBFE);
  static const surfaceDark = Color(0xFF1C1B1F);
  static const onSurface = Color(0xFF1C1B1F);
  static const onSurfaceDark = Color(0xFFE6E1E5);
}
