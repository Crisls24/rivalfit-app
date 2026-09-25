import 'dart:typed_data';

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

/// Identidad visual unica de una liga: la foto de grupo si existe; si no, el
/// [LeagueEmblem] (podio de la marca). Reemplaza por completo los emojis e
/// iconos como identidad de liga. Se usa en el sheet de creacion (preview en
/// vivo), el dialog de exito, la card, el invite sheet, el join y el ranking.
class LeagueBadge extends StatelessWidget {
  /// URL publica de la foto ya subida a storage.
  final String? photoUrl;

  /// Bytes de la foto recien elegida (preview local ANTES de subir).
  final Uint8List? bytes;

  final double size;

  /// Radio de las esquinas de la caja cuadrada.
  final double radius;

  final Color? background;

  final Color? borderColor;

  const LeagueBadge({
    super.key,
    this.photoUrl,
    this.bytes,
    this.size = 48,
    this.radius = 14,
    this.background,
    this.borderColor,
  });

  bool get _hasImage => (photoUrl?.isNotEmpty ?? false) || bytes != null;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? AppColors.volt.withValues(alpha: 0.14);
    final border = borderColor ?? AppColors.volt.withValues(alpha: 0.28);
    final borderRadius = BorderRadius.circular(radius);

    if (!_hasImage) {
      return _frame(
        borderRadius,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: borderRadius,
          border: Border.all(color: border, width: 1.2),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(size * 0.14),
            child: LeagueEmblem(size: size * 0.72),
          ),
        ),
      );
    }

    final image = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover)
        : Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _frame(
              borderRadius,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: borderRadius,
                border: Border.all(color: border, width: 1.2),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(size * 0.14),
                  child: LeagueEmblem(size: size * 0.72),
                ),
              ),
            ),
          );

    return _frame(
      borderRadius,
      decoration: BoxDecoration(color: bg, borderRadius: borderRadius),
      clip: true,
      child: image,
    );
  }

  Widget _frame(
    BorderRadius borderRadius, {
    required BoxDecoration decoration,
    Widget? child,
    bool clip = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: decoration,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: child,
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