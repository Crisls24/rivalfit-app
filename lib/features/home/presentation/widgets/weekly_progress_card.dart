import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/exercise/domain/models/saved_training_session.dart';
import 'package:rivalfit/features/exercise/presentation/controllers/training_storage_providers.dart';

class WeeklyProgressCard extends ConsumerWidget {
  const WeeklyProgressCard({super.key});

  static const _goal = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(savedTrainingSessionsProvider);
    final today = DateTime.now();
    final monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - DateTime.monday),
    );
    final mondayUtc = monday.toUtc();
    final nextMondayUtc = DateTime(
      monday.year,
      monday.month,
      monday.day + DateTime.daysPerWeek,
    ).toUtc();
    final count = sessions.valueOrNull?.where((session) {
      final completedAt = session.result.endedAtUtc;
      final saved = switch (session.state) {
        SavedSessionState.pending ||
        SavedSessionState.confirmed => session.result.eligibleForSubmission,
        SavedSessionState.personal => session.result.eligibleForLocalHistory,
        _ => false,
      };
      return saved &&
          !completedAt.isBefore(mondayUtc) &&
          completedAt.isBefore(nextMondayUtc);
    }).length;
    final completed = (count ?? 0) >= _goal;
    final status = count == null
        ? (sessions.hasError ? 'Avance no disponible' : 'Cargando…')
        : (completed ? 'Meta cumplida' : 'Meta $_goal sesiones');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Esta semana',
          style: TextStyle(
            color: AppColors.carbon,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (count != null) ...[
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'sesión' : 'sesiones'}',
            style: const TextStyle(
              color: AppColors.carbon,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.12,
              letterSpacing: -0.7,
            ),
          ),
        ],
        const SizedBox(height: 5),
        Row(
          children: [
            if (completed) ...[
              const Icon(
                Icons.check_rounded,
                color: Color(0xFF527600),
                size: 17,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(child: Text(status, style: const TextStyle(fontSize: 12))),
          ],
        ),
      ],
    );
  }
}
