import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/app/widgets/app_card.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rivalfit/features/exercise/domain/models/exercise.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_providers.dart';

import '../widgets/daily_steps_card.dart';
import '../widgets/recommended_routine_card.dart';
import '../widgets/weekly_progress_card.dart';

class TrainingView extends ConsumerWidget {
  final VoidCallback onGoToLeague;

  const TrainingView({super.key, required this.onGoToLeague});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final hasLeague = ref.watch(
      leagueControllerProvider.select((state) => state.league != null),
    );
    final name = user?.displayName.trim() ?? '';
    final photoUrl = user?.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final initials = name.isEmpty ? 'R' : name.characters.first.toUpperCase();

    return ColoredBox(
      color: AppColors.iceBackground,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'RivalFit',
                          style: TextStyle(
                            color: AppColors.carbon,
                            fontSize: 31,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.4,
                            height: 1.1,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.carbon,
                        foregroundImage: hasPhoto
                            ? NetworkImage(photoUrl)
                            : null,
                        onForegroundImageError: hasPhoto ? (_, _) {} : null,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const RecommendedRoutineCard(),
                  const SizedBox(height: 15),
                  const _SectionHeading('Ejercicios libres'),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final scale =
                          MediaQuery.textScalerOf(context).scale(14) / 14;
                      final width = constraints.maxWidth >= 285 * scale
                          ? (constraints.maxWidth - 8) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final exercise in appExercises)
                            SizedBox(
                              width: width,
                              child: _MovementTile(exercise: exercise),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const _SectionHeading('Tu actividad'),
                  const SizedBox(height: 10),
                  const _ActivityPanel(),
                  const SizedBox(height: 12),
                  AppCard(
                    showShadow: false,
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                    onTap: hasLeague
                        ? () => context.push('/league/ranking')
                        : onGoToLeague,
                    child: const Row(
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          color: AppColors.carbon,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Liga semanal',
                            style: TextStyle(
                              color: AppColors.carbon,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text('Ver liga', textAlign: TextAlign.end),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 17),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppColors.carbon,
      fontSize: 23,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.55,
    ),
  );
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showShadow: false,
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          if (constraints.maxWidth < 260 * scale) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DailyStepsCard(),
                Divider(height: 24, color: AppColors.subtleBorder),
                WeeklyProgressCard(),
              ],
            );
          }
          return const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: DailyStepsCard()),
                VerticalDivider(
                  width: 24,
                  thickness: 1,
                  color: AppColors.subtleBorder,
                ),
                Expanded(child: WeeklyProgressCard()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showShadow: false,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      padding: EdgeInsets.zero,
      onTap: () => context.push('/exercise/${exercise.id}'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final artworkWidth = (constraints.maxWidth * 0.48).clamp(55.0, 112.0);
          final squat = exercise.id == 'sentadillas';
          return Stack(
            children: [
              Positioned(
                right: 6,
                bottom: 4,
                child: Image.asset(
                  'assets/icons/pose-${exercise.id}.png',
                  width: artworkWidth,
                  height: squat ? 68 : 52,
                  alignment: Alignment.bottomRight,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 82),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(11, 9, 9, squat ? 10 : 35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: AppColors.carbon,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.35,
                        ),
                      ),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
