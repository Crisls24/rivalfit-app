import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/app/widgets/app_card.dart';
import 'package:rivalfit/features/exercise/domain/models/exercise.dart';

/// Card del catalogo de ejercicios de la tab "Entrenar". Muestra icono,
/// nombre y grupo muscular; al tocarla abre la ruta de detalle del ejercicio.
/// El conteo de reps del dia se conectara cuando existan sesiones (Fase 3).
class ExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/exercise/${exercise.id}'),
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
        ],
      ),
    );
  }
}