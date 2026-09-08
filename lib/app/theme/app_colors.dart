import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFA83DF2);
  static const Color accent = Color(0xFFEE5C7D);
  static const Color danger = Color(0xFFC62828);

  // Glassmorphism
  static const Color backgroundDark = Color(0xFF1A0A2E);
  static const Color backgroundDeep = Color(0xFF0F0519);
  static const Color glowPurple = Color(0xFF7B2FBE);
  static const Color glowPink = Color(0xFFEE5C7D);

  // Glass panel
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBackground = Color(0x1AFFFFFF);

  // Inputs
  static const Color inputBackground = Color(0x33FFFFFF);
  static const Color inputBorder = Color(0x4DFFFFFF);
  static const Color inputIcon = Color(0xFF9E9E9E);

  // Text
  static const Color textWhite = Colors.white;
  static const Color textGray = Color(0xFFB0B0B0);
  static const Color textPlaceholder = Color(0xFF808080);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFA83DF2), Color(0xFFEE5C7D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Password strength
  static const Color strengthWeak = Color(0xFFC62828);
  static const Color strengthMedium = Color(0xFFF57C00);
  static const Color strengthStrong = Color(0xFF2E7D32);

  // Social button background
  static const Color socialCardBg = Color(0x1AFFFFFF);
  static const Color socialCardBorder = Color(0x33FFFFFF);

  // Semantic
  static const Color success = Color(0xFF2E7D32);

  // Brutal / Modo Bestia
  static const Color volt = Color(0xFFCCFF00);
  static const Color asphalt = Color(0xFF121212);
  static const Color brutalCard = Color(0xFF1E1E1E);

  // Nivel de entrenamiento (acentos por nivel)
  static const Color intermediateOrange = Color(0xFFFF7A00);
  static const Color advancedCoral = Color(0xFFFF3B30);

  // Clean White Sports
  static const Color carbon = Color(0xFF111111);
  static const Color iceBackground = Color(0xFFF8F9FA);
  static const Color grayMain = Color(0xFF666666);
  static const Color subtleBorder = Color(0xFFE5E5EA);
  static const Color avatarBackground = Color(0xFFF0F0F2);
  static const Color panelSoft = Color(0xFFF4F4F6);
}
