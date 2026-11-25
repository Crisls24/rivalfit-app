import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/exercise/domain/models/saved_training_session.dart';
import 'package:rivalfit/features/exercise/domain/models/training_session.dart';
import 'package:rivalfit/features/exercise/presentation/controllers/training_storage_providers.dart';

import '../controllers/league_providers.dart';

class LeagueTrainingAction extends ConsumerWidget {
  const LeagueTrainingAction({super.key});

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

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.carbon,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () async {
        final movement = await showModalBottomSheet<TrainingMovement>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final move in [
                  TrainingMovement.squat,
                  TrainingMovement.pushUp,
                ])
                  ListTile(
                    title: Text('Entrenar ${move.label.toLowerCase()}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(sheet, move),
                  ),
              ],
            ),
          ),
        );
        if (movement != null && context.mounted) {
          await _train(context, ref, movement);
        }
      },
      child: const Text(
        'Sumar puntos',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    );
  }
}
