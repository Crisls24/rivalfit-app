import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/exercise/domain/models/exercise.dart';

/// Card de un ejercicio del catálogo. Muestra icono, nombre, grupo muscular y
/// un mini-conteo del día; al tocarla abre la ruta de detalle/sesión.
class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final int repsToday;

  const ExerciseCard({super.key, required this.exercise, this.repsToday = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/exercise/${exercise.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.subtleBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: exercise.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(exercise.icon, size: 24, color: exercise.accent),
            ),
            const Spacer(),
            Text(
              exercise.name,
              style: const TextStyle(
                color: AppColors.carbon,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              exercise.muscleLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.grayMain.withValues(alpha: 0.85),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 13, color: AppColors.volt),
                const SizedBox(width: 4),
                Text(
                  '$repsToday reps hoy',
                  style: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}