import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/exercise/domain/models/training_session.dart';

import 'exercise_pose_icon.dart';

const _routineName = 'Cuerpo completo';
const _routineDetails = '8 min · 3 ejercicios';
const _routineExercises = [
  (name: 'Sentadillas', target: '10 reps', movement: TrainingMovement.squat),
  (name: 'Lagartijas', target: '6 reps', movement: TrainingMovement.pushUp),
  (name: 'Plancha', target: '20 s', movement: TrainingMovement.plank),
];

class RecommendedRoutineCard extends StatelessWidget {
  const RecommendedRoutineCard({super.key});

  Future<void> _showRoutine(BuildContext context) async {
    final selected = await showModalBottomSheet<TrainingMovement>(
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
                  leading: ExercisePoseIcon(exercise.movement),
                  title: Text(exercise.name),
                  subtitle: Text(exercise.target),
                ),
              const SizedBox(height: 12),
              _RoutineButton(
                label: 'Empezar sentadillas',
                onPressed: () =>
                    Navigator.of(context).pop(TrainingMovement.squat),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(TrainingMovement.pushUp),
                child: const Text('Empezar lagartijas'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(TrainingMovement.plank),
                child: const Text('Empezar plancha'),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && context.mounted) {
      context.push('/exercise/${selected.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: AppColors.carbon,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _RoutineCover(),
            const Divider(height: 1, thickness: 1, color: Color(0xFF494949)),
            const IntrinsicHeight(
              child: Row(
                children: [
                  _RoutineDose('10 sentadillas'),
                  VerticalDivider(
                    width: 1,
                    indent: 8,
                    endIndent: 8,
                    color: Color(0xFF666666),
                  ),
                  _RoutineDose('6 lagartijas'),
                  VerticalDivider(
                    width: 1,
                    indent: 8,
                    endIndent: 8,
                    color: Color(0xFF666666),
                  ),
                  _RoutineDose('20 s de plancha'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 3, 10, 10),
              child: _RoutineButton(
                label: 'Empezar rutina',
                onPressed: () => _showRoutine(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineDose extends StatelessWidget {
  const _RoutineDose(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _RoutineCover extends StatelessWidget {
  const _RoutineCover();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: constraints.maxWidth * 1.16,
              child: Image.asset(
                'assets/training/full-body.webp',
                fit: BoxFit.cover,
                alignment: Alignment.topRight,
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
                minHeight: (constraints.maxWidth * 0.49).clamp(160.0, 260.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.64,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Rutina de hoy',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Cuerpo\ncompleto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontStyle: FontStyle.italic,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      icon: const Icon(Icons.play_arrow_rounded, size: 25),
      label: Text(label, textAlign: TextAlign.center),
    );
  }
}
