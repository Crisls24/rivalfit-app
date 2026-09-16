import 'package:flutter/material.dart';

/// Paleta de RivalFit — "Neon Minimalism + Competitive Sports".
///
/// Lima = identidad de marca (Rival Lime). Naranja/rojo son SOLO acentos de
/// nivel dentro de la seleccion de rango. Negro = intensidad / competicion.
/// Hueso = calma / navegacion. El neon funciona mejor cuando escasea.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFB8FF00);
  static const Color volt = Color(0xFFB8FF00);
  static const Color danger = Color(0xFFC62828);

  // Modo claro (hueso + negro + lima)
  static const Color base = Color(0xFFF7F7F5);
  static const Color carbon = Color(0xFF111111);

  // Dark world (negro + lima escaso)
  static const Color backgroundDark = Color(0xFF111111);
  static const Color backgroundDeep = Color(0xFF070707);
  static const Color glowNeutral = Color(0xFF1C1C1E);
  static const Color glowLime = Color(0xFFB8FF00);

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

  // Password strength
  static const Color strengthWeak = Color(0xFFC62828);
  static const Color strengthMedium = Color(0xFFF57C00);
  static const Color strengthStrong = Color(0xFF2E7D32);

  // Social button background
  static const Color socialCardBg = Color(0x1AFFFFFF);
  static const Color socialCardBorder = Color(0x33FFFFFF);

  // Semantic
  static const Color success = Color(0xFF2E7D32);

  // Nivel de entrenamiento (solo dentro de la seleccion de rango)
  static const Color intermediateOrange = Color(0xFFFF7A00);
  static const Color advancedCoral = Color(0xFFFF3D3D);

  // Clear Light Sports
  static const Color iceBackground = Color(0xFFF7F7F5);
  static const Color grayMain = Color(0xFF666666);
  static const Color subtleBorder = Color(0xFFE5E5EA);
  static const Color avatarBackground = Color(0xFFF0F0F2);
  static const Color panelSoft = Color(0xFFF4F4F6);
}