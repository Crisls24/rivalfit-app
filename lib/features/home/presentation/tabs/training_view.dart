import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/app/widgets/app_card.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rivalfit/features/exercise/domain/models/exercise.dart';
import 'package:rivalfit/features/exercise/domain/models/training_session.dart';
import 'package:rivalfit/features/exercise/presentation/widgets/saved_training_sessions_card.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_providers.dart';

import '../widgets/exercise_card.dart';
import '../widgets/recommended_routine_card.dart';
import '../widgets/weekly_progress_card.dart';

class TrainingView extends ConsumerWidget {
  static const backgroundColor = Color(0xFFF8F5EF);
  static const _freeExercise = SquatSessionRules.exerciseId;

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
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
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
                            fontSize: 28,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.4,
                            height: 1.1,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF4F2CA7),
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
                  const SizedBox(height: 16),
                  const Text(
                    'Tu rutina de hoy',
                    style: TextStyle(
                      color: AppColors.carbon,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const RecommendedRoutineCard(),
                  const SizedBox(height: 16),
                  const WeeklyProgressCard(),
                  const SizedBox(height: 8),
                  AppCard(
                    showShadow: false,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    padding: const EdgeInsets.all(12),
                    onTap: hasLeague
                        ? () => context.push('/league/ranking')
                        : onGoToLeague,
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 17,
                          backgroundColor: Color(0xFFE8F7BF),
                          foregroundColor: AppColors.carbon,
                          child: Icon(Icons.leaderboard_outlined, size: 19),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Tu Liga',
                            style: TextStyle(
                              color: AppColors.carbon,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            hasLeague ? 'Ver ranking' : 'Ver ligas',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: AppColors.grayMain,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.carbon,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ejercicios libres',
                    style: TextStyle(
                      color: AppColors.carbon,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ExerciseCard(
                    exercise: appExercises.firstWhere(
                      (e) => e.id == _freeExercise,
                    ),
                    available: true,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Próximamente',
                    style: TextStyle(
                      color: AppColors.grayMain,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 8.0;
                      final scale =
                          MediaQuery.textScalerOf(context).scale(14) / 14;
                      final columns = constraints.maxWidth / scale >= 280
                          ? 2
                          : 1;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final exercise in appExercises.where(
                            (e) => e.id != _freeExercise,
                          ))
                            SizedBox(
                              width: width,
                              child: ExerciseCard(exercise: exercise),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const SavedTrainingSessionsCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
