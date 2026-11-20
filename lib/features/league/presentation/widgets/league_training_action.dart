import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/exercise/domain/models/saved_training_session.dart';
import 'package:rivalfit/features/exercise/domain/models/training_session.dart';
import 'package:rivalfit/features/exercise/presentation/controllers/training_storage_providers.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';

import '../controllers/league_providers.dart';

class LeagueTrainingAction extends ConsumerWidget {
  final List<LeagueMember> ranking;
  final String? currentUserId;

  const LeagueTrainingAction({
    super.key,
    required this.ranking,
    required this.currentUserId,
  });

  Future<void> _train(
    BuildContext context,
    WidgetRef ref,
    TrainingMovement movement,
  ) async {
    await context.push('/exercise/${movement.id}?from=league');
    if (context.mounted) {
      await ref.read(leagueControllerProvider.notifier).loadRanking();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(savedTrainingSessionsProvider, (previous, next) {
      final before = previous?.valueOrNull;
      final after = next.valueOrNull;
      if (before == null || after == null) return;
      final waiting = {
        for (final session in before)
          if (session.state == SavedSessionState.pending)
            session.result.sessionId,
      };
      if (after.any(
        (session) =>
            session.state == SavedSessionState.confirmed &&
            waiting.contains(session.result.sessionId),
      )) {
        ref.read(leagueControllerProvider.notifier).loadRanking();
      }
    });

    final index = ranking.indexWhere(
      (member) => member.userId == currentUserId,
    );
    final String? status;
    if (index < 0) {
      status = null;
    } else if (index == 0) {
      status = ranking.length > 1 ? 'Vas en 1.er lugar' : 'Puesto 1';
    } else {
      final gap = ranking[index - 1].weeklyPoints - ranking[index].weeklyPoints;
      status = gap == 0
          ? 'Puesto ${index + 1} · Empate en puntos con el puesto anterior'
          : 'Puesto ${index + 1} · A $gap ${gap == 1 ? 'punto' : 'puntos'} del puesto anterior';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status != null) ...[
            Text(status, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: () => _train(context, ref, TrainingMovement.squat),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.volt,
              foregroundColor: AppColors.carbon,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.fitness_center_rounded),
            label: const Text('Entrenar sentadillas'),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () => _train(context, ref, TrainingMovement.pushUp),
            child: const Text('Entrenar lagartijas'),
          ),
        ],
      ),
    );
  }
}
