import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

const _routineName = 'Cuerpo completo';
const _routineDetails = '8 min · 3 ejercicios';
const _routineExercises = [
  (name: 'Sentadillas', target: '10 reps', movement: _Movement.squat),
  (name: 'Lagartijas', target: '6 reps', movement: _Movement.pushUp),
  (name: 'Plancha', target: '20 s', movement: _Movement.plank),
];

class RecommendedRoutineCard extends StatelessWidget {
  const RecommendedRoutineCard({super.key});

  Future<void> _showRoutine(BuildContext context) async {
    final startSquats = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _routineName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Rutina recomendada · $_routineDetails',
                style: const TextStyle(color: AppColors.grayMain),
              ),
              const SizedBox(height: 12),
              for (final exercise in _routineExercises)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _PoseIcon(exercise.movement),
                  title: Text(exercise.name),
                  subtitle: Text(
                    exercise.movement == _Movement.squat
                        ? exercise.target
                        : '${exercise.target} · Próximamente',
                  ),
                ),
              const SizedBox(height: 12),
              _RoutineButton(
                label: 'Empezar sentadillas',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
    if (startSquats == true && context.mounted) {
      context.push('/session');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A111111),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: ColoredBox(
          color: AppColors.carbon,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _RoutineCover(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFAF5),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: const Color(0xFFE3DFD6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 13, 10, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _ExercisePreview(),
                      const SizedBox(height: 14),
                      _RoutineButton(
                        label: 'Empezar rutina',
                        onPressed: () => _showRoutine(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineCover extends StatelessWidget {
  const _RoutineCover();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/training/full-body.webp',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.carbon,
                      Color(0xCC111111),
                      Color(0x00111111),
                    ],
                    stops: [0, 0.34, 0.65],
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxWidth * 0.59).clamp(174.0, 290.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.63,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cuerpo\ncompleto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 0.99,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _routineDetails,
                        style: TextStyle(
                          color: Color(0xFFE0E0DC),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExercisePreview extends StatelessWidget {
  const _ExercisePreview();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
        final columnsFit = constraints.maxWidth / scale >= 265;
        final tiles = [
          for (final exercise in _routineExercises)
            Column(
              children: [
                _PoseIcon(exercise.movement),
                const SizedBox(height: 4),
                Text(
                  exercise.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  exercise.target,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grayMain,
                  ),
                ),
              ],
            ),
        ];
        if (!columnsFit) {
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: tiles,
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, tile) in tiles.indexed) ...[
                if (index > 0)
                  const VerticalDivider(
                    width: 9,
                    thickness: 1,
                    color: Color(0xFFE3DFD6),
                  ),
                Expanded(child: tile),
              ],
            ],
          ),
        );
      },
    );
  }
}

enum _Movement { squat, pushUp, plank }

class _PoseIcon extends StatelessWidget {
  const _PoseIcon(this.movement);

  final _Movement movement;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(42, 30),
      painter: _PosePainter(movement),
    );
  }
}

class _PosePainter extends CustomPainter {
  const _PosePainter(this.movement);

  final _Movement movement;

  @override
  void paint(Canvas canvas, Size size) {
    final (head, torso, arms) = switch (movement) {
      _Movement.squat => (
        const Offset(22, 6),
        const [Offset(18, 13), Offset(13, 22), Offset(22, 21), Offset(18, 28)],
        const [Offset(18, 14), Offset(29, 13)],
      ),
      _Movement.pushUp => (
        const Offset(35, 9),
        const [Offset(28, 11), Offset(17, 15), Offset(6, 21), Offset(6, 24)],
        const [Offset(27, 12), Offset(26, 24), Offset(32, 24)],
      ),
      _Movement.plank => (
        const Offset(36, 12),
        const [Offset(29, 15), Offset(18, 17), Offset(6, 20), Offset(6, 23)],
        const [Offset(29, 16), Offset(28, 24), Offset(36, 24)],
      ),
    };
    final paint = Paint()
      ..color = AppColors.carbon
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(head, 3.5, paint);
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(Path()..addPolygon(torso, false), paint);
    canvas.drawPath(Path()..addPolygon(arms, false), paint);
  }

  @override
  bool shouldRepaint(covariant _PosePainter oldDelegate) =>
      oldDelegate.movement != movement;
}

class _RoutineButton extends StatelessWidget {
  const _RoutineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.volt,
        foregroundColor: AppColors.carbon,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      icon: const Icon(Icons.play_arrow_rounded, size: 25),
      label: Text(label, textAlign: TextAlign.center),
    );
  }
}
