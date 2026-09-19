import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Stepper horizontal: número de paso a la izquierda + barra segmentada de
/// progreso (completadas en negro, actual en acento, siguientes en gris).
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final Color accent;
  final ValueChanged<int>? onStepTap;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.accent,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '0$currentStep',
          style: const TextStyle(
            color: AppColors.carbon,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '/ 03',
          style: TextStyle(
            color: AppColors.grayMain.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onStepTap == null ? null : () => onStepTap!(i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        height: 7,
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: i + 1 < currentStep
                              ? AppColors.carbon
                              : i + 1 == currentStep
                                  ? accent
                                  : const Color(0xFFE5E5EA),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: i + 1 == currentStep
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.45),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}