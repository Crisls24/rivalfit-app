import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

import '../../domain/models/training_session.dart';

class TrainingSetupGuide extends StatefulWidget {
  const TrainingSetupGuide({super.key, required this.movement});

  final TrainingMovement movement;

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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Antes de empezar',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      ExcludeSemantics(
        child: CustomPaint(
          size: const Size(0, 132),
          painter: _ExerciseDemo(_motion, widget.movement),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        widget.movement == TrainingMovement.squat
            ? 'Apoya el celular en el piso frente a ti. Aléjate hasta que se vean tu cabeza y tus pies.'
            : 'Coloca el celular en el piso, frente a ti y un poco a un lado. Mantén las manos y los pies dentro del cuadro.',
        style: const TextStyle(color: Colors.white, height: 1.4),
      ),
      const SizedBox(height: 8),
      const Text(
        'Con el sonido activado, la cuenta regresiva te avisa cuando estás listo.',
        style: TextStyle(color: Colors.white70, height: 1.4),
      ),
      const SizedBox(height: 8),
      Text(
        widget.movement == TrainingMovement.squat
            ? 'Empieza de pie. Baja y vuelve a ponerte de pie para sumar una repetición.'
            : 'Empieza en plancha con los brazos extendidos. Baja el pecho y vuelve a extender los brazos.',
        style: const TextStyle(color: Colors.white, height: 1.4),
      ),
    ],
  );
}

class _ExerciseDemo extends CustomPainter {
  _ExerciseDemo(this.motion, this.movement) : super(repaint: motion);

  final Animation<double> motion;
  final TrainingMovement movement;

  @override
  void paint(Canvas canvas, Size size) {
    const diagram = Size(204, 132);
    final scale = (size.width / diagram.width).clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(
      (size.width - diagram.width * scale) / 2,
      (size.height - diagram.height * scale) / 2,
    );
    canvas.scale(scale);

    final outline = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(86, 5, 103, 108),
        const Radius.circular(12),
      ),
      outline,
    );
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

  @override
  bool shouldRepaint(covariant _ExerciseDemo oldDelegate) =>
      oldDelegate.motion != motion || oldDelegate.movement != movement;
}
