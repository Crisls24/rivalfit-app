import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Pantalla de sesión (placeholder de la Fase 1). Aquí vivirá el flujo
/// selector de ejercicio -> tutorial -> cámara con conteo por IA (Fase 2).
class SessionPlaceholderPage extends StatelessWidget {
  const SessionPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.carbon,
        elevation: 0,
        title: const Text(
          'Empezar entrenamiento',
          style: TextStyle(
            color: AppColors.carbon,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.volt.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.videocam_outlined,
                    size: 34,
                    color: AppColors.carbon,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Próximamente',
                  style: TextStyle(
                    color: AppColors.carbon,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La sesión con cámara y verificación por IA llega en la siguiente fase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}