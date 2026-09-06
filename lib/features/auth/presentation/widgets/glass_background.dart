import 'package:flutter/material.dart';
import 'package:autohost/app/theme/app_colors.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;
  final bool showBaseGradient;
  final bool showDecorations;

  const GlassBackground({
    super.key,
    required this.child,
    this.showBaseGradient = true,
    this.showDecorations = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBaseGradient && !showDecorations) {
      return child;
    }

    return Stack(
      children: [
        // ── Base dark gradient ─────────────────────────────────────────
        if (showBaseGradient)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundDeep,
                  AppColors.backgroundDark,
                  Color(0xFF1E0835),
                ],
              ),
            ),
          ),

        if (showDecorations) ...[
          // ── Blob 1: Gran nube púrpura arriba-izquierda ───────────────
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.glowPurple.withValues(alpha: 0.28),
                    AppColors.glowPurple.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // ── Blob 2: Nube rosa-fucsia abajo-derecha ───────────────────
          Positioned(
            bottom: -140,
            right: -100,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.glowPink.withValues(alpha: 0.22),
                    AppColors.glowPink.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.40, 1.0],
                ),
              ),
            ),
          ),

          // ── Blob 3: Nube primary abajo-izquierda ────────────────────
          Positioned(
            bottom: 60,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.50, 1.0],
                ),
              ),
            ),
          ),

          // ── Blob 4: Toque rosa pequeño arriba-derecha ────────────────
          Positioned(
            top: 80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.14),
                    AppColors.accent.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // ── Estrellas / partículas ───────────────────────────────────
          const _StarField(),
        ],

        // ── Contenido ───────────────────────────────────────────────────
        child,
      ],
    );
  }
}

/// Puntos blancos fijos dispersos como estrellas.
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    // Posiciones fijas (relativas a la pantalla) para las estrellas
    const stars = [
      // (left%, top%, size, opacity)
      (0.08, 0.12, 2.0, 0.55),
      (0.22, 0.07, 1.5, 0.40),
      (0.55, 0.04, 2.5, 0.60),
      (0.80, 0.10, 1.5, 0.45),
      (0.92, 0.18, 2.0, 0.50),
      (0.15, 0.30, 1.5, 0.35),
      (0.70, 0.25, 2.0, 0.50),
      (0.40, 0.20, 1.5, 0.40),
      (0.88, 0.40, 2.5, 0.55),
      (0.05, 0.55, 1.5, 0.30),
      (0.30, 0.60, 2.0, 0.45),
      (0.65, 0.68, 1.5, 0.35),
      (0.90, 0.72, 2.0, 0.50),
      (0.18, 0.80, 2.5, 0.40),
      (0.50, 0.88, 1.5, 0.35),
      (0.75, 0.92, 2.0, 0.45),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: stars.map((s) {
            final (lp, tp, size, opacity) = s;
            return Positioned(
              left: constraints.maxWidth * lp,
              top: constraints.maxHeight * tp,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: opacity),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
