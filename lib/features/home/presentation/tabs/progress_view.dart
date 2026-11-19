import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../training_progress.dart';
import '../../../exercise/presentation/controllers/training_storage_providers.dart';

import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/app/widgets/app_card.dart';
import 'package:rivalfit/features/home/presentation/widgets/muscle_map_card.dart';
import 'package:rivalfit/features/home/presentation/widgets/progress_emblem.dart';

class ProgressView extends ConsumerWidget {
  final List<String> earnedTrophies;

  const ProgressView({super.key, this.earnedTrophies = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainingProgressProvider);
    final progress = state.valueOrNull ?? const TrainingProgress(0, 0);
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mi progreso',
              style: TextStyle(
                color: AppColors.carbon,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Tu rango y los músculos que dominas.',
              style: TextStyle(
                color: AppColors.grayMain,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (state.isLoading) const LinearProgressIndicator(),
            if (state.hasError)
              TextButton(
                onPressed: () => ref.invalidate(savedTrainingSessionsProvider),
                child: const Text('No se pudo cargar tu progreso. Reintentar'),
              ),
            if (progress.pendingReps > 0)
              Text(
                '${progress.pendingReps} repeticiones pendientes de sincronizar',
              ),
            MuscleMapCard(legReps: progress.confirmedReps),
            const SizedBox(height: 24),
            _RankCard(progress: progress),
            const SizedBox(height: 24),
            const Text(
              'Insignias',
              style: TextStyle(
                color: AppColors.carbon,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _TrophyCollection(
              earnedTrophies: {
                ...earnedTrophies,
                ...progress.trophies,
              }.toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  final TrainingProgress progress;
  const _RankCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ProgressEmblem(
                icon: Icons.bolt_rounded,
                finish: ProgressEmblemFinish.volt,
                size: 46,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.rank.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.carbon,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rango global',
                      style: TextStyle(
                        color: AppColors.grayMain.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Nv. ${progress.level}',
                style: TextStyle(
                  color: AppColors.grayMain,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 9,
              backgroundColor: AppColors.panelSoft,
              valueColor: AlwaysStoppedAnimation(AppColors.volt),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress.rankCaption,
            style: TextStyle(
              color: AppColors.grayMain,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyCollection extends StatelessWidget {
  final List<String> earnedTrophies;

  const _TrophyCollection({required this.earnedTrophies});

  @override
  Widget build(BuildContext context) {
    if (earnedTrophies.isEmpty) {
      return const AppCard(
        showShadow: false,
        child: Row(
          children: [
            ProgressEmblem(
              icon: Icons.emoji_events_outlined,
              finish: ProgressEmblemFinish.steel,
              size: 42,
              medallion: true,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tus trofeos aparecerán aquí al desbloquearlos.',
                style: TextStyle(color: AppColors.grayMain, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final title in earnedTrophies)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              showShadow: false,
              child: Row(
                children: [
                  const ProgressEmblem(
                    icon: Icons.emoji_events_rounded,
                    finish: ProgressEmblemFinish.bronze,
                    size: 46,
                    medallion: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.carbon,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
