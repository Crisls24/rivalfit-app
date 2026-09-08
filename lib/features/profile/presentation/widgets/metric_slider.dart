import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Stat tile de peso/altura: número base gigante, slider fino con acento
/// y steppers −/+. Tono carbón sobre superficie clara para legibilidad.
class MetricSlider extends StatelessWidget {
  final String label;
  final String unit;
  final double min;
  final double max;
  final double value;
  final double step;
  final Color accent;
  final ValueChanged<double> onChanged;

  const MetricSlider({
    super.key,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.accent = AppColors.volt,
  });

  String get _display {
    final intPart = value.floor();
    final decimal = (value % 1) * 10;
    final decimals = decimal.round();
    return decimals >= 1 ? '$intPart.$decimals' : '$intPart';
  }

  void _bump(double dir) {
    onChanged((value + dir * step).clamp(min, max));
  }

  @override
  Widget build(BuildContext context) {
    final fmin = min.roundToDouble();
    final fmax = max.roundToDouble();
    final divisions = (((fmax - fmin) / step).floor()).clamp(1, 1000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.carbon,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                unit.toUpperCase(),
                style: TextStyle(
                  color: accent == AppColors.volt
                      ? AppColors.carbon
                      : accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Row(
              key: ValueKey('$label$_display'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _display,
                  style: const TextStyle(
                    color: AppColors.carbon,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  unit,
                  style: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: accent,
            inactiveTrackColor: const Color(0xFFEFEFF2),
            thumbColor: AppColors.carbon,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 7,
              elevation: 1,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value.clamp(fmin, fmax),
            min: fmin,
            max: fmax,
            divisions: divisions,
            overlayColor: WidgetStatePropertyAll(
              accent.withValues(alpha: 0.20),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepButton(icon: Icons.remove, onTap: () => _bump(-step)),
            const SizedBox(width: 24),
            _StepButton(icon: Icons.add, onTap: () => _bump(step)),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE3E3E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.carbon),
      ),
    );
  }
}