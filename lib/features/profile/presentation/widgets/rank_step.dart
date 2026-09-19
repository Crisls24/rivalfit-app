import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/auth/domain/entities/user.dart';

/// Paso 3 — Rango / Nivel.
///
/// Tres cards de selección con estructura idéntica: icono, nombre del nivel,
/// descripción corta e indicador de selección. La personalidad viene de la
/// tipografía, los iconos y el color de acento, sin elementos decorativos.
class RankStep extends StatelessWidget {
  final FitnessLevel? selectedLevel;
  final ValueChanged<FitnessLevel> onLevelSelected;

  const RankStep({
    super.key,
    required this.selectedLevel,
    required this.onLevelSelected,
  });

  Color _accentFor(FitnessLevel level) => switch (level) {
        FitnessLevel.beginner => AppColors.volt,
        FitnessLevel.intermediate => AppColors.intermediateOrange,
        FitnessLevel.advanced => AppColors.advancedCoral,
      };

  IconData _iconFor(FitnessLevel level) => switch (level) {
        FitnessLevel.beginner => Icons.directions_run_rounded,
        FitnessLevel.intermediate => Icons.fitness_center_rounded,
        FitnessLevel.advanced => Icons.local_fire_department_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < FitnessLevel.values.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _LevelCard(
              level: FitnessLevel.values[i],
              accent: _accentFor(FitnessLevel.values[i]),
              icon: _iconFor(FitnessLevel.values[i]),
              selected: selectedLevel == FitnessLevel.values[i],
              onTap: () => onLevelSelected(FitnessLevel.values[i]),
            )
                .animate(delay: Duration(milliseconds: 80 + i * 80))
                .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                .slideY(begin: 0.05, end: 0, duration: 300.ms),
          ],
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.group_add_rounded,
                  size: 15,
                  color: AppColors.grayMain.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'Tu rango se mostrará junto a tu nombre en la Liga.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.grayMain.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

// ─────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final FitnessLevel level;
  final Color accent;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.accent,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? accent : AppColors.subtleBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? accent.withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: selected ? 20 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: selected ? accent : AppColors.panelSoft,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                icon,
                size: 27,
                color: selected
                    ? (accent == AppColors.volt ? Colors.black : Colors.white)
                    : AppColors.grayMain,
              ),
            ),
            const SizedBox(width: 16),

            // Nombre + descripción
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    level.label,
                    style: TextStyle(
                      color: AppColors.carbon.withValues(
                        alpha: selected ? 1.0 : 0.85,
                      ),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.grayMain.withValues(alpha: 0.88),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Indicador de selección (único)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : Colors.transparent,
                border: Border.all(
                  color: selected ? accent : const Color(0xFFCFCFD6),
                  width: 2,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded,
                      size: 15,
                      color: accent == AppColors.volt ? Colors.black : Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}