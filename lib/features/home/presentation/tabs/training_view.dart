import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/auth/domain/entities/user.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rivalfit/features/exercise/domain/models/exercise.dart';

import '../widgets/exercise_card.dart';
import '../widgets/weekly_progress_card.dart';

/// Tab "Entrenar": el centro de la experiencia. Saludo con avatar, resumen
/// semanal, CTA para iniciar sesion y el catalogo de ejercicios verificados.
class TrainingView extends ConsumerWidget {
  final VoidCallback onGoToLeague;

  const TrainingView({super.key, required this.onGoToLeague});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(user: user),
            const SizedBox(height: 18),
            const WeeklyProgressCard(),
            const SizedBox(height: 18),
            _HeroCta(),
            const SizedBox(height: 26),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ejercicios',
                  style: TextStyle(
                    color: AppColors.carbon,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Cámara + IA',
                  style: TextStyle(
                    color: AppColors.grayMain,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.02,
              children: [
                for (final exercise in appExercises)
                  ExerciseCard(exercise: exercise),
              ],
            ),
            const SizedBox(height: 18),
            _LeagueSnapshot(onGoToLeague: onGoToLeague),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  final User? user;

  const _Header({this.user});

  ImageProvider? get _photo {
    final photoUrl = user?.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) return null;
    return NetworkImage(photoUrl);
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName.trim().toLowerCase() ?? '';
    final fitnessLevel = user?.fitnessLevel?.label;
    final tagline = fitnessLevel == null
        ? '¿Qué vas a hacer hoy?'
        : 'Nivel $fitnessLevel';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Qué vas a hacer hoy?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.carbon,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                name.isEmpty ? tagline : '@$name · $tagline',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.grayMain.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _Avatar(photo: _photo, name: name),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final ImageProvider? photo;
  final String name;

  const _Avatar({required this.photo, required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isEmpty
        ? 'R'
        : name.split(' ').take(2).map((p) => p[0]).join().toUpperCase();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.subtleBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: photo != null
            ? Image(image: photo!, fit: BoxFit.cover)
            : Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.carbon,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
      ),
    );
  }
}

class _HeroCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.carbon,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.volt.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Empezar entrenamiento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'La cámara y la IA verifican cada repetición',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Material(
            color: AppColors.volt,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => context.push('/session'),
              customBorder: const CircleBorder(),
              splashColor: Colors.black26,
              child: const SizedBox(
                width: 54,
                height: 54,
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 30,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueSnapshot extends StatelessWidget {
  final VoidCallback onGoToLeague;

  const _LeagueSnapshot({required this.onGoToLeague});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.volt.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.group_add_rounded,
              size: 24,
              color: AppColors.carbon,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu Liga',
                  style: TextStyle(
                    color: AppColors.carbon,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Crea o únete a una liga y compite contra hasta 10 amigos.',
                  style: TextStyle(
                    color: AppColors.grayMain,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.carbon,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onGoToLeague,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  'Ir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}