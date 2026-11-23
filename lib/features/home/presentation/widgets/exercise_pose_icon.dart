import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/exercise/domain/models/training_session.dart';

class ExercisePoseIcon extends StatelessWidget {
  const ExercisePoseIcon(this.movement, {super.key, this.width = 42});

  final TrainingMovement movement;
  final double width;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size(width, width * 30 / 42),
      painter: _PosePainter(movement),
    ),
  );
}

class _PosePainter extends CustomPainter {
  const _PosePainter(this.movement);

  final TrainingMovement movement;

  @override
  void paint(Canvas canvas, Size size) {
    final (head, body, arms) = switch (movement) {
      TrainingMovement.squat => (
        const Offset(22, 5),
        const [Offset(19, 11), Offset(13, 21), Offset(23, 21), Offset(18, 27)],
        const [Offset(18, 13), Offset(30, 12)],
      ),
      TrainingMovement.pushUp => (
        const Offset(35, 14),
        const [Offset(29, 16), Offset(17, 18), Offset(6, 23), Offset(6, 26)],
        const [Offset(28, 16), Offset(23, 13), Offset(24, 25), Offset(30, 25)],
      ),
      TrainingMovement.crunch => (
        const Offset(9, 12),
        const [Offset(14, 16), Offset(22, 24), Offset(30, 15), Offset(36, 25)],
        const [Offset(14, 16), Offset(19, 14), Offset(23, 17)],
      ),
      TrainingMovement.plank => (
        const Offset(35, 10),
        const [Offset(28, 13), Offset(17, 17), Offset(6, 21), Offset(6, 25)],
        const [Offset(28, 13), Offset(27, 24), Offset(36, 24)],
      ),
    };
    canvas.save();
    canvas.scale(size.width / 42, size.height / 30);
    final paint = Paint()
      ..color = AppColors.carbon
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(head, 3.4, paint);
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(Path()..addPolygon(body, false), paint);
    canvas.drawPath(Path()..addPolygon(arms, false), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PosePainter oldDelegate) =>
      oldDelegate.movement != movement;
}
