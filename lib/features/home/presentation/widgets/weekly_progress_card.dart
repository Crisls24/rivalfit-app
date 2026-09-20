import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/app/widgets/app_card.dart';

/// Tarjeta de "Resumen de la semana": puntos semanales con barra de progreso
/// y chip de racha. Los contadores se conectaran a sesiones reales (Fase 3);
/// por ahora arrancan en cero.
class WeeklyProgressCard extends StatelessWidget {
  final int weeklyPoints;
  final int weeklyTarget;
  final int currentStreak;

  const WeeklyProgressCard({
    super.key,
    this.weeklyPoints = 0,
    this.weeklyTarget = 100,
    this.currentStreak = 0,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (weeklyPoints / weeklyTarget).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Resumen de la semana',
                style: TextStyle(
                  color: AppColors.carbon,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: AppColors.carbon,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Racha $currentStreak',
                      style: const TextStyle(
                        color: AppColors.carbon,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Puntos semanales',
                style: TextStyle(
                  color: AppColors.grayMain,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$weeklyPoints / $weeklyTarget',
                style: const TextStyle(
                  color: AppColors.carbon,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 9,
              backgroundColor: AppColors.panelSoft,
              valueColor: const AlwaysStoppedAnimation(AppColors.volt),
            ),
          ),
        ],
      ),
    );
  }
}