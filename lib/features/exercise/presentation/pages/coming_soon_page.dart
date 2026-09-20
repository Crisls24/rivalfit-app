import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Placeholder generico de la Fase 1: pantalla con AppBar, icono destacado y
/// mensaje "Proximamente". Lo usan las rutas de detalle de ejercicio y de
/// sesion real hasta que lleguen el tutorial animado y la camara con IA.
class ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const ComingSoonPage({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.carbon,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
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
                  child: Icon(icon, size: 34, color: AppColors.carbon),
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
                  message,
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