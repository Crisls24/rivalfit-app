import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/app/widgets/app_card.dart';
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
      return (session.state == SavedSessionState.pending ||
              session.state == SavedSessionState.confirmed) &&
          session.result.eligibleForSubmission &&
          !completedAt.isBefore(mondayUtc) &&
          completedAt.isBefore(nextMondayUtc);
    }).length;
    final completed = (count ?? 0) >= _goal;
    final status = count == null
        ? (sessions.hasError ? 'Avance no disponible' : 'Cargando…')
        : '$count de $_goal sesiones';

    return AppCard(
      showShadow: false,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tu semana',
                  style: TextStyle(
                    color: AppColors.carbon,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: completed
                        ? const Color(0xFFE8F7BF)
                        : AppColors.panelSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.carbon,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < _goal; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: i < (count ?? 0)
                            ? AppColors.volt
                            : const Color(0xFFE5E4E0),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
