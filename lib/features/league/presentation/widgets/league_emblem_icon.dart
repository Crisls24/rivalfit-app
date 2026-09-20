import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Emblema de Liga: anillos concéntricos (arena) coronados por un podio de
/// tres barras volt, la central más alta. Geometría propia de RivalFit, sin
/// emojis ni ilustraciones genéricas: representa "aquí comienza la
/// competencia".
///
/// Es la identidad visual de la sección Liga y se reutilizará en estados
/// posteriores (liga del usuario, invitaciones, ranking, liga completa).
class LeagueEmblem extends StatelessWidget {
  final double size;

  const LeagueEmblem({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LeagueEmblemPainter(size)),
    );
  }
}

class _LeagueEmblemPainter extends CustomPainter {
  final double size;

  _LeagueEmblemPainter(this.size);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final r = canvasSize.width / 2;

    // Anillo exterior: borde del "campo" de la arena.
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.05
      ..color = Colors.white.withValues(alpha: 0.20);
    canvas.drawCircle(center, r - r * 0.07, outer);

    // Anillo interior: el circuito donde se disputara el ranking.
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.05
      ..color = AppColors.volt.withValues(alpha: 0.32);
    canvas.drawCircle(center, r - r * 0.36, inner);

    // Podio: tres pilares sobre una linea base, el central mas alto.
    final baselineY = center.dy + r * 0.36;
    final barWidth = r * 0.19;
    final sideHeight = r * 0.52;
    final topHeight = r * 0.74;
    final sideOffset = r * 0.34;

    _drawBar(
      canvas,
      cx: center.dx - sideOffset,
      width: barWidth,
      height: sideHeight,
      baselineY: baselineY,
      color: AppColors.volt.withValues(alpha: 0.45),
    );
    _drawBar(
      canvas,
      cx: center.dx + sideOffset,
      width: barWidth,
      height: sideHeight,
      baselineY: baselineY,
      color: AppColors.volt.withValues(alpha: 0.45),
    );
    _drawBar(
      canvas,
      cx: center.dx,
      width: barWidth * 1.12,
      height: topHeight,
      baselineY: baselineY,
      color: AppColors.volt,
    );
  }

  void _drawBar(
    Canvas canvas, {
    required double cx,
    required double width,
    required double height,
    required double baselineY,
    required Color color,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - width / 2, baselineY - height, width, height),
        Radius.circular(width / 2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LeagueEmblemPainter oldDelegate) {
    return oldDelegate.size != size;
  }
}