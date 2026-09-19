import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Paso 2 — Métricas base.
/// Dos diales numéricos (Peso | Altura) en columna con botones +/- circulares
/// con acento de color. Sin slider horizontal: diseño limpio tipo "reloj".
class MetricsStep extends StatelessWidget {
  final double weightKg;
  final int heightCm;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onHeightChanged;

  const MetricsStep({
    super.key,
    required this.weightKg,
    required this.heightCm,
    required this.onWeightChanged,
    required this.onHeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricDial(
                  label: 'PESO',
                  value: weightKg,
                  unit: 'kg',
                  min: 40,
                  max: 160,
                  step: 0.5,
                  accent: AppColors.volt,
                  onChanged: onWeightChanged,
                )
                    .animate(delay: 80.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.06, end: 0, duration: 300.ms),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricDial(
                  label: 'ALTURA',
                  value: heightCm.toDouble(),
                  unit: 'cm',
                  min: 120,
                  max: 220,
                  step: 1,
                  accent: AppColors.carbon,
                  onChanged: (v) => onHeightChanged(v.round()),
                )
                    .animate(delay: 140.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.06, end: 0, duration: 300.ms),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: AppColors.carbon.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Podrás ajustar estas métricas más adelante',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.carbon.withValues(alpha: 0.55),
                      fontSize: 11.5,
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

/// Dial numérico: número grande + botones +/- circulares con acento.
class _MetricDial extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
  final double step;
  final Color accent;
  final ValueChanged<double> onChanged;

  const _MetricDial({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.accent,
    required this.onChanged,
  });

  String get _display {
    final intPart = value.floor();
    final decimal = ((value % 1) * 10).round();
    return decimal >= 1 ? '$intPart.$decimal' : '$intPart';
  }

  bool get _isDecimal => step < 1;

  Future<void> _editValue(BuildContext context) async {
    final onAccent = accent == AppColors.volt ? Colors.black : Colors.white;
    var input = _display;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$label · $unit',
                    style: const TextStyle(
                      color: AppColors.carbon,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _display,
                autofocus: true,
                keyboardType: _isDecimal
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  LengthLimitingTextInputFormatter(5),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.carbon,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.iceBackground,
                  hintStyle: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.subtleBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: accent, width: 1.6),
                  ),
                ),
                onChanged: (v) => input = v,
                onFieldSubmitted: (v) => Navigator.pop(ctx, v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: AppColors.grayMain,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, input),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: onAccent,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Listo',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;
    final cleaned = result.trim().replaceAll(',', '.');
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return;
    final raw = parsed.clamp(min, max);
    final stepped = min + ((raw - min) / step).round() * step;
    onChanged(stepped.clamp(min, max));
  }

  void _bump(double delta) {
    final raw = (value + delta).clamp(min, max);
    final stepped = min + ((raw - min) / step).round() * step;
    onChanged(stepped.clamp(min, max));
  }

  @override
  Widget build(BuildContext context) {
    final canDecrease = value > min + 0.0001;
    final canIncrease = value < max - 0.0001;
    final onAccent = accent == AppColors.volt ? Colors.black : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Label tag ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent == AppColors.volt
                  ? AppColors.volt.withValues(alpha: 0.15)
                  : AppColors.carbon.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.carbon,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── Botón + ──
          _DialButton(
            icon: Icons.add_rounded,
            enabled: canIncrease,
            accent: accent,
            onAccent: onAccent,
            onTap: () => _bump(step),
          ),

          const SizedBox(height: 14),

          // ── Número grande (tocable: abre teclado numérico) ──
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _editValue(context),
              borderRadius: BorderRadius.circular(16),
              splashColor: accent.withValues(alpha: 0.08),
              highlightColor: accent.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _display,
                        key: ValueKey(_display),
                        style: const TextStyle(
                          color: AppColors.carbon,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        color: AppColors.grayMain.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Botón - ──
          _DialButton(
            icon: Icons.remove_rounded,
            enabled: canDecrease,
            accent: accent,
            onAccent: onAccent,
            onTap: () => _bump(-step),
          ),
        ],
      ),
    );
  }
}

class _DialButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color accent;
  final Color onAccent;
  final VoidCallback onTap;

  const _DialButton({
    required this.icon,
    required this.enabled,
    required this.accent,
    required this.onAccent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? accent : AppColors.subtleBorder,
      shape: const CircleBorder(),
      elevation: enabled ? 0 : 0,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        splashColor: Colors.white30,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 22,
            color: enabled
                ? onAccent
                : AppColors.grayMain.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
