import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/app/widgets/app_card.dart';
import 'package:rivalfit/features/exercise/domain/models/exercise.dart';
import 'package:rivalfit/features/exercise/domain/models/training_session.dart';

import 'exercise_pose_icon.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool available;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.available = false,
  });

  @override
  Widget build(BuildContext context) {
    final movement = TrainingMovement.forId(exercise.id);
    return AppCard(
      padding: EdgeInsets.all(available ? 12 : 9),
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      showShadow: false,
      onTap: () => context.push('/exercise/${exercise.id}'),
      child: Row(
        children: [
          CircleAvatar(
            radius: available ? 19 : 15,
            backgroundColor: available
                ? const Color(0xFFE8F7BF)
                : AppColors.panelSoft,
            foregroundColor: AppColors.carbon,
            child: movement == null
                ? Icon(exercise.icon, size: available ? 21 : 17)
                : ExercisePoseIcon(movement, width: available ? 32 : 26),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    color: AppColors.carbon,
                    fontSize: available ? 16 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (available)
                  Text(
                    exercise.muscleLabel,
                    style: const TextStyle(
                      color: AppColors.grayMain,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (available) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.volt,
              foregroundColor: AppColors.carbon,
              child: Icon(Icons.play_arrow_rounded, size: 21),
            ),
          ],
        ],
      ),
    );
  }
}
