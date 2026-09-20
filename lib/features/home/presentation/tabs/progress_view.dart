import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Tab "Mi progreso": rango global (PRD seccion 4.5), rango por grupo
/// muscular (Bronce -> Diamante) e insignias. Los datos llegan en la Fase 3;
/// aquí se muestra la estructura con contadores en cero.
class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
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
            const _RankCard(),
            const SizedBox(height: 24),
            const Text(
              'Músculos',
              style: TextStyle(
                color: AppColors.carbon,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.0,
              children: const [
                _MuscleCard(
                  icon: Icons.fitness_center_rounded,
                  label: 'Pecho y brazos',
                ),
                _MuscleCard(
                  icon: Icons.accessibility_new_rounded,
                  label: 'Piernas',
                ),
                _MuscleCard(
                  icon: Icons.sports_gymnastics,
                  label: 'Core',
                ),
                _MuscleCard(
                  icon: Icons.monitor_heart_rounded,
                  label: 'Cardio',
                ),
              ],
            ),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.panelSoft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.subtleBorder),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 42,
                    color: AppColors.grayMain.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aún no tienes insignias',
                    style: TextStyle(
                      color: AppColors.grayMain.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Se desbloquean al alcanzar hitos (rachas, marcas y rangos).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.grayMain.withValues(alpha: 0.75),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  const _RankCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  size: 24,
                  color: AppColors.carbon,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOVATO',
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
              const Spacer(),
              const Text(
                'Nv. 0',
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
            child: const LinearProgressIndicator(
              value: 0,
              minHeight: 9,
              backgroundColor: AppColors.panelSoft,
              valueColor: AlwaysStoppedAnimation(AppColors.volt),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '0 / 50 reps para subir a Principiante',
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

class _MuscleCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MuscleCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.volt.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.carbon),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.carbon,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'BRONCE · 0 reps',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}