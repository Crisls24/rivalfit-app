import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

class GlassBackground extends StatefulWidget {
  final Widget child;
  final bool showBaseGradient;
  final bool showDecorations;
  final bool animatedAurora;

  const GlassBackground({
    super.key,
    required this.child,
    this.showBaseGradient = true,
    this.showDecorations = true,
    this.animatedAurora = false,
  });

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassBackgroundState extends State<GlassBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _auroraController;

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    );
    if (widget.animatedAurora) {
      _auroraController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GlassBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animatedAurora && !oldWidget.animatedAurora) {
      _auroraController.repeat();
    } else if (!widget.animatedAurora && oldWidget.animatedAurora) {
      _auroraController.stop();
    }
  }

  @override
  void dispose() {
    _auroraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showBaseGradient && !widget.showDecorations) {
      return widget.child;
    }

    final showAurora = widget.showDecorations && widget.animatedAurora;

    return Stack(
      children: [
        if (widget.showBaseGradient) const _BaseGradient(),

        if (showAurora)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _auroraController,
                builder: (context, _) {
                  final t = _auroraController.value;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _AuroraField(t: t),
                      _FloatingParticles(t: t),
                      _FloatingStarField(t: t),
                      _CenterGlow(t: t),
                      const _Vignette(),
                    ],
                  );
                },
              ),
            ),
          )
        else if (widget.showDecorations) ...[
          const _StaticBlobs(),
          const _StaticStarField(),
        ],

        widget.child,
      ],
    );
  }
}

/// Onda senoidal para parametros animados (cycles = vueltas en un ciclo completo).
double _wave(double t, double cycles, double phase) =>
    math.sin((t * cycles + phase) * 2 * math.pi);

double _wrapUnit(double v) => ((v % 1) + 1) % 1;

// ─────────────────────────────────────────────────────────────────────────────
//  Capas base
// ─────────────────────────────────────────────────────────────────────────────

/// Gradiente base oscuro (degradado de fondo).
class _BaseGradient extends StatelessWidget {
  const _BaseGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

/// Blobs estaticos del modo clasico.
class _StaticBlobs extends StatelessWidget {
  const _StaticBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        // Gran nube purpura arriba-izquierda
        Positioned(
          top: -120,
          left: -100,
          child: _Blob(
            size: 380,
            color: AppColors.glowPurple,
            alpha: 0.28,
          ),
        ),
        // Nube rosa-fucsia abajo-derecha
        Positioned(
          bottom: -140,
          right: -100,
          child: _Blob(
            size: 420,
            color: AppColors.glowPink,
            alpha: 0.22,
          ),
        ),
        // Nube primary abajo-izquierda
        Positioned(
          bottom: 60,
          left: -80,
          child: _Blob(
            size: 280,
            color: AppColors.primary,
            alpha: 0.15,
          ),
        ),
        // Toque rosa pequeno arriba-derecha
        Positioned(
          top: 80,
          right: -60,
          child: _Blob(
            size: 220,
            color: AppColors.accent,
            alpha: 0.14,
          ),
        ),
      ],
    );
  }
}

/// Blob circular con gradiente radial suave.
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;

  const _Blob({
    required this.size,
    required this.color,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Modo aurora animado
// ─────────────────────────────────────────────────────────────────────────────

/// Blobs de color que derivan suavemente por la pantalla.
class _AuroraField extends StatelessWidget {
  final double t;

  const _AuroraField({required this.t});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blob A: purpura arriba-izquierda
        Positioned(
          left: -100 + _wave(t, 1.0, 0.0) * 130,
          top: -120 + _wave(t, 0.8, 0.3) * 80,
          child: _Blob(
            size: 380 + _wave(t, 0.5, 0.6) * 55,
            color: AppColors.glowPurple,
            alpha: (0.30 + _wave(t, 0.6, 1.2) * 0.06).clamp(0.05, 0.36),
          ),
        ),
        // Blob B: rosa abajo-derecha
        Positioned(
          right: -100 + _wave(t, 0.9, 0.5) * 115,
          bottom: -140 + _wave(t, 0.7, 0.1) * 90,
          child: _Blob(
            size: 420 + _wave(t, 0.4, 0.8) * 65,
            color: AppColors.glowPink,
            alpha: (0.24 + _wave(t, 0.5, 0.4) * 0.06).clamp(0.05, 0.30),
          ),
        ),
        // Blob C: primary abajo-izquierda
        Positioned(
          left: -80 + _wave(t, 0.7, 0.3) * 80,
          bottom: 60 + _wave(t, 0.6, 0.9) * 100,
          child: _Blob(
            size: 280 + _wave(t, 0.4, 0.2) * 45,
            color: AppColors.primary,
            alpha: (0.16 + _wave(t, 0.5, 0.7) * 0.05).clamp(0.04, 0.22),
          ),
        ),
        // Blob D: accent arriba-derecha (pequeno)
        Positioned(
          right: -60 + _wave(t, 0.9, 0.7) * 90,
          top: 80 + _wave(t, 0.6, 0.5) * 60,
          child: _Blob(
            size: 220 + _wave(t, 0.5, 1.1) * 40,
            color: AppColors.accent,
            alpha: (0.15 + _wave(t, 0.7, 0.2) * 0.05).clamp(0.04, 0.20),
          ),
        ),
      ],
    );
  }
}

/// Particulas flotantes que ascienden lentamente y oscilan en horizontal.
class _FloatingParticles extends StatelessWidget {
  final double t;

  const _FloatingParticles({required this.t});

  // (left%, rise offset, speed, sway, swayFreq, phase, size, baseOpacity, tint)
  // tint: 0 = blanco, 1 = rosa, 2 = purpura
  static const List<(double, double, double, double, double, double, double,
      double, int)> _particles = [
    (0.06, 0.05, 0.30, 0.04, 0.5, 0.0, 3.0, 0.60, 2),
    (0.18, 0.20, 0.22, 0.03, 0.7, 0.4, 1.6, 0.40, 0),
    (0.31, 0.10, 0.27, 0.05, 0.4, 1.2, 2.6, 0.55, 0),
    (0.47, 0.35, 0.18, 0.03, 0.6, 0.8, 1.6, 0.35, 0),
    (0.58, 0.15, 0.25, 0.04, 0.5, 2.0, 3.4, 0.60, 1),
    (0.72, 0.28, 0.20, 0.03, 0.8, 1.6, 1.7, 0.40, 0),
    (0.86, 0.08, 0.29, 0.05, 0.5, 0.6, 3.0, 0.55, 2),
    (0.95, 0.42, 0.16, 0.02, 0.6, 2.4, 1.4, 0.35, 0),
    (0.12, 0.55, 0.14, 0.04, 0.5, 3.0, 2.0, 0.32, 0),
    (0.24, 0.70, 0.17, 0.03, 0.6, 0.2, 3.2, 0.42, 1),
    (0.40, 0.80, 0.13, 0.05, 0.4, 2.2, 1.5, 0.30, 0),
    (0.52, 0.60, 0.19, 0.03, 0.7, 1.0, 2.4, 0.42, 0),
    (0.66, 0.85, 0.12, 0.04, 0.5, 2.8, 1.5, 0.28, 2),
    (0.80, 0.65, 0.16, 0.05, 0.6, 0.5, 2.8, 0.45, 0),
    (0.92, 0.75, 0.14, 0.03, 0.5, 1.8, 1.6, 0.30, 1),
    (0.03, 0.88, 0.12, 0.05, 0.4, 0.0, 1.6, 0.28, 0),
    (0.70, 0.40, 0.21, 0.04, 0.6, 3.2, 2.0, 0.38, 0),
    (0.35, 0.93, 0.11, 0.03, 0.5, 2.6, 1.4, 0.26, 0),
    (0.48, 0.07, 0.33, 0.04, 0.9, 0.9, 3.8, 0.62, 1),
    (0.15, 0.90, 0.10, 0.06, 0.4, 3.4, 3.2, 0.50, 2),
    (0.88, 0.90, 0.10, 0.05, 0.5, 0.3, 3.6, 0.55, 0),
    (0.62, 0.82, 0.12, 0.06, 0.7, 1.4, 2.6, 0.40, 0),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final p in _particles)
              _buildParticle(constraints, p),
          ],
        );
      },
    );
  }

  Widget _buildParticle(
      BoxConstraints constraints,
      (double, double, double, double, double, double, double, double,
          int) p) {
    final (leftFrac, riseOffset, speed, sway, swayFreq, phase, size,
        baseOpacity, tint) = p;

    // Posicion vertical que asciende: se mueve de abajo hacia arriba y reinicia.
    final progress = _wrapUnit(riseOffset + t * speed * 1.3);
    final x = leftFrac + sway * _wave(t, swayFreq, phase);

    final opacity = (baseOpacity *
            (0.75 + 0.25 * math.sin((t * 0.7 + phase) * 2 * math.pi)))
        .clamp(0.08, baseOpacity);

    final color = switch (tint) {
      1 => AppColors.glowPink,
      2 => AppColors.glowPurple,
      _ => Colors.white,
    };

    return Positioned(
      left: constraints.maxWidth * x - size / 2,
      bottom: constraints.maxHeight * progress,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: size * 1.5,
                spreadRadius: size * 0.3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Posiciones fijas (left%, top%, size, baseOpacity) de las estrellas.
const List<(double, double, double, double)> _starPositions = [
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

/// Estrellas blancas fijas (modo clasico).
class _StaticStarField extends StatelessWidget {
  const _StaticStarField();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: _starPositions.map((s) {
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

/// Estrellas que titilan (opacidad pulsante) para el modo aurora.
class _FloatingStarField extends StatelessWidget {
  final double t;

  const _FloatingStarField({required this.t});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (int i = 0; i < _starPositions.length; i++)
              _buildStar(constraints, _starPositions[i], i),
          ],
        );
      },
    );
  }

  Widget _buildStar(
      BoxConstraints constraints, (double, double, double, double) s, int i) {
    final (lp, tp, size, baseOpacity) = s;
    // Fase distinta por estrella para que titilen desincronizadas.
    final phase = i * 0.37;
    final opacity =
        (baseOpacity * (0.45 + 0.55 * _wave(t, 1.6, phase)))
            .clamp(0.08, baseOpacity);

    return Positioned(
      left: constraints.maxWidth * lp,
      top: constraints.maxHeight * tp,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Resplandor suave detras del area central (donde va el panel) que respira.
class _CenterGlow extends StatelessWidget {
  final double t;

  const _CenterGlow({required this.t});

  @override
  Widget build(BuildContext context) {
    final alpha = (0.12 + 0.05 * _wave(t, 0.9, 1.2)).clamp(0.05, 0.18);
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, 0.05),
          radius: 0.78,
          colors: [
            AppColors.primary.withValues(alpha: alpha),
            AppColors.glowPurple.withValues(alpha: alpha * 0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

/// Vignette suave que oscurece los bordes para enfocar el panel central.
class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.2,
          colors: [
            Colors.transparent,
            AppColors.backgroundDeep.withValues(alpha: 0.38),
          ],
          stops: const [0.55, 1.0],
        ),
      ),
    );
  }
}