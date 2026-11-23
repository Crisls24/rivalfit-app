import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

import '../../domain/models/training_session.dart';

class TrainingSetupGuide extends StatefulWidget {
  const TrainingSetupGuide({
    super.key,
    required this.movement,
    required this.onStart,
  });

  final TrainingMovement movement;
  final VoidCallback onStart;

  @override
  State<TrainingSetupGuide> createState() => _TrainingSetupGuideState();
}

class _TrainingSetupGuideState extends State<TrainingSetupGuide>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
      _motion.value = 1;
    } else if (!_motion.isAnimating) {
      _motion.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (framing, motion) = switch (widget.movement) {
      TrainingMovement.squat => (
        'Apoya el celular en el piso frente a ti. Deja visibles la cabeza y los pies.',
        'Empieza de pie. Baja la cadera y vuelve a ponerte de pie.',
      ),
      TrainingMovement.pushUp => (
        'Apoya el celular enfrente, un poco a un lado. Deja visibles las manos y los pies.',
        'Empieza en plancha con los brazos extendidos. Baja el pecho y vuelve a subir.',
      ),
      TrainingMovement.crunch => (
        'Coloca el celular bajo y en diagonal a un lado. Deja visibles los hombros, la cadera y los pies.',
        'Recuéstate boca arriba con las rodillas flexionadas. Eleva los hombros y bájalos con control.',
      ),
      TrainingMovement.plank => (
        'Coloca el celular bajo y en diagonal a un lado. Deja visibles el torso y los pies.',
        'Apoya los antebrazos y las puntas de los pies. Mantén hombros, cadera y tobillos alineados.',
      ),
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final demoHeight = (constraints.maxHeight * .36).clamp(
              152.0,
              286.0,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    children: [
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF252923), AppColors.carbon],
                          ),
                        ),
                        child: RepaintBoundary(
                          child: ExcludeSemantics(
                            child: CustomPaint(
                              size: Size(double.infinity, demoHeight),
                              painter: _ExerciseDemo(_motion, widget.movement),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Cómo hacerlo',
                        style: TextStyle(
                          fontSize: 24,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.carbon,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _GuideStep(
                        icon: Icons.center_focus_strong_rounded,
                        title: 'Encuadra tu cuerpo',
                        detail: framing,
                      ),
                      const Divider(height: 18),
                      _GuideStep(
                        icon: Icons.fitness_center_rounded,
                        title: widget.movement == TrainingMovement.plank
                            ? 'Mantén la postura'
                            : 'Haz el movimiento',
                        detail: motion,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: widget.onStart,
                        icon: const Icon(Icons.videocam_rounded),
                        label: const Text('Activar cámara'),
                        style: FilledButton.styleFrom(
                          foregroundColor: AppColors.carbon,
                          backgroundColor: AppColors.volt,
                          minimumSize: const Size.fromHeight(56),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'El video se analiza en tu teléfono, sin grabarlo ni enviarlo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.grayMain,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.volt.withValues(alpha: .2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: AppColors.carbon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.carbon,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: AppColors.grayMain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseDemo extends CustomPainter {
  _ExerciseDemo(this.motion, this.movement) : super(repaint: motion);

  final Animation<double> motion;
  final TrainingMovement movement;

  @override
  void paint(Canvas canvas, Size size) {
    const diagram = Size(204, 132);
    final scale = ((size.width - 32) / diagram.width).clamp(
      0.0,
      (size.height - 24) / diagram.height,
    );
    canvas.save();
    canvas.translate(
      (size.width - diagram.width * scale) / 2,
      (size.height - diagram.height * scale) / 2,
    );
    canvas.scale(scale);

    final outline = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(86, 5, 103, 108),
        const Radius.circular(12),
      ),
      outline,
    );
    final guideMarks = Paint()
      ..color = AppColors.volt.withValues(alpha: .38)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final (x, y, dx, dy) in [
      (91.0, 13.0, 1, 1),
      (184.0, 13.0, -1, 1),
      (91.0, 105.0, 1, -1),
      (184.0, 105.0, -1, -1),
    ]) {
      final corner = Offset(x, y);
      canvas.drawLine(corner, corner + Offset(dx * 10.0, 0), guideMarks);
      canvas.drawLine(corner, corner + Offset(0, dy * 10.0), guideMarks);
    }
    canvas.drawLine(const Offset(16, 120), const Offset(187, 120), outline);
    final accent = Paint()..color = AppColors.volt;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 94, 15, 26),
        const Radius.circular(3),
      ),
      accent,
    );
    canvas.drawLine(const Offset(43, 98), const Offset(79, 48), outline);
    canvas.drawLine(const Offset(43, 100), const Offset(79, 108), outline);

    final t = Curves.easeInOut.transform(motion.value);
    if (movement == TrainingMovement.crunch ||
        movement == TrainingMovement.plank) {
      _paintCore(canvas, accent, t);
      canvas.restore();
      return;
    }
    if (movement == TrainingMovement.pushUp) {
      _paintPushUp(canvas, accent, t);
      canvas.restore();
      return;
    }
    final hip = Offset(lerpDouble(143, 156, t)!, lerpDouble(62, 84, t)!);
    final shoulder = Offset(lerpDouble(142, 135, t)!, lerpDouble(30, 56, t)!);
    final knee = Offset(lerpDouble(142, 124, t)!, lerpDouble(86, 85, t)!);
    final hands = Offset(lerpDouble(138, 109, t)!, lerpDouble(58, 60, t)!);
    final head = shoulder - Offset(lerpDouble(2, 6, t)!, 13);
    const ankle = Offset(144, 104);
    const toes = Offset(132, 108);
    canvas.drawCircle(head, 7, accent);
    accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()..addPolygon([shoulder, hip, knee, ankle, toes], false),
      accent,
    );
    canvas.drawLine(shoulder, hands, accent);
    canvas.restore();
  }

  void _paintPushUp(Canvas canvas, Paint paint, double t) {
    final shoulder = Offset.lerp(
      const Offset(112, 78),
      const Offset(109, 96),
      t,
    )!;
    final hip = Offset.lerp(const Offset(146, 89), const Offset(146, 100), t)!;
    final elbow = Offset.lerp(const Offset(114, 93), const Offset(123, 99), t)!;
    canvas.drawCircle(shoulder + const Offset(-8, -5), 6, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()..addPolygon([shoulder, hip, const Offset(179, 110)], false),
      paint,
    );
    canvas.drawPath(
      Path()..addPolygon([shoulder, elbow, const Offset(115, 110)], false),
      paint,
    );
  }

  void _paintCore(Canvas canvas, Paint paint, double t) {
    final plank = movement == TrainingMovement.plank;
    final shoulder = plank
        ? const Offset(112, 78)
        : Offset(lerpDouble(112, 118, t)!, lerpDouble(102, 86, t)!);
    final hip = plank ? const Offset(145, 92) : const Offset(143, 109);
    final knee = plank ? const Offset(163, 100) : const Offset(156, 85);
    const ankle = Offset(176, 109);
    if (plank) {
      canvas.drawLine(
        shoulder,
        ankle,
        Paint()
          ..color = Colors.white.withValues(alpha: .2 + t * .6)
          ..strokeWidth = 2,
      );
    }
    canvas.drawCircle(shoulder + const Offset(-8, -5), 6, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()..addPolygon([shoulder, hip, knee, ankle], false),
      paint,
    );
    if (plank) {
      canvas.drawPath(
        Path()..addPolygon([
          shoulder,
          const Offset(115, 109),
          const Offset(100, 109),
        ], false),
        paint,
      );
    } else {
      canvas.drawLine(shoulder, shoulder + const Offset(12, -3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExerciseDemo oldDelegate) =>
      oldDelegate.motion != motion || oldDelegate.movement != movement;
}
