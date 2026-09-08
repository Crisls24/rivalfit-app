import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/auth/domain/entities/user.dart';

/// Card de nivel rediseñada en clave "rank de combate":
/// - Medallón circular con icono animado (rebote/contracción/carga).
/// - 3 barras de stats (Potencia / Técnica / Aguante) según el nivel.
/// - Al elegir uno, los demás (dimmed) se comprimen con AnimatedSize
///   (efecto "desafío") y pierden opacidad.
class LevelCard extends StatefulWidget {
  final FitnessLevel level;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  const LevelCard({
    super.key,
    required this.level,
    required this.selected,
    required this.onTap,
    this.dimmed = false,
  });

  @override
  State<LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<LevelCard> {
  bool _pressed = false;

  Color get _accent => switch (widget.level) {
        FitnessLevel.beginner => AppColors.volt,
        FitnessLevel.intermediate => AppColors.intermediateOrange,
        FitnessLevel.advanced => AppColors.advancedCoral,
      };

  IconData get _icon => switch (widget.level) {
        FitnessLevel.beginner => Icons.directions_run,
        FitnessLevel.intermediate => Icons.fitness_center,
        FitnessLevel.advanced => Icons.local_fire_department,
      };

  String get _rank => switch (widget.level) {
        FitnessLevel.beginner => 'I',
        FitnessLevel.intermediate => 'II',
        FitnessLevel.advanced => 'III',
      };

  /// (label, valor 1..3) de cada stat. Perfil distinto por rango.
  List<(String, int)> get _stats => switch (widget.level) {
        FitnessLevel.beginner => [
            ('POTENCIA', 1),
            ('TÉCNICA', 1),
            ('AGUANTE', 1),
          ],
        FitnessLevel.intermediate => [
            ('POTENCIA', 2),
            ('TÉCNICA', 3),
            ('AGUANTE', 2),
          ],
        FitnessLevel.advanced => [
            ('POTENCIA', 3),
            ('TÉCNICA', 3),
            ('AGUANTE', 3),
          ],
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 260),
          opacity: widget.dimmed ? 0.5 : 1,
          child: AnimatedScale(
            scale: _pressed ? 0.985 : widget.selected ? 1.02 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: widget.selected
                    ? _accent.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: widget.selected ? _accent : const Color(0xFFECECF0),
                  width: widget.selected ? 2 : 1,
                ),
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.30),
                          blurRadius: 26,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.045),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: widget.dimmed ? _buildCompact() : _buildFull(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return Row(
      children: [
        _Medallion(
          accent: _accent,
          selected: widget.selected,
          icon: _icon,
          trait: _trait,
          size: 50,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            widget.level.label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.carbon,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFull() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Medallion(
          accent: _accent,
          selected: widget.selected,
          icon: _icon,
          trait: _trait,
          size: 56,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.level.label.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.carbon,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: widget.selected ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'RANK $_rank',
                      style: TextStyle(
                        color: widget.selected ? _accent : AppColors.carbon,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.level.description,
                style: const TextStyle(
                  color: AppColors.grayMain,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < _stats.length; i++) ...[
                    Expanded(child: _StatBar(label: _stats[i].$1, value: _stats[i].$2, accent: _accent, selected: widget.selected)),
                    if (i < _stats.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  _Trait get _trait => switch (widget.level) {
        FitnessLevel.beginner => _Trait.bounce,
        FitnessLevel.intermediate => _Trait.pulse,
        FitnessLevel.advanced => _Trait.strong,
      };
}

enum _Trait { bounce, pulse, strong }

/// Medallón circular con icono animado según el nivel.
class _Medallion extends StatelessWidget {
  final Color accent;
  final bool selected;
  final IconData icon;
  final _Trait trait;
  final double size;

  const _Medallion({
    required this.accent,
    required this.selected,
    required this.icon,
    required this.trait,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    Widget plate() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: selected ? accent : const Color(0xFFF5F5F7),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? accent : const Color(0xFFE3E3E8),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: size * 0.52,
            color: selected ? Colors.black : AppColors.carbon,
          ),
        );

    final animated = switch (trait) {
      _Trait.bounce => plate()
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -3, duration: 700.ms, curve: Curves.easeInOut),
      _Trait.pulse => plate()
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(0.94, 1.06),
            duration: 620.ms,
            curve: Curves.easeInOut,
          ),
      _Trait.strong => plate()
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.12, 1.12),
            duration: 460.ms,
            curve: Curves.easeInOut,
          ),
    };

    return animated;
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  final Color accent;
  final bool selected;

  const _StatBar({
    required this.label,
    required this.value,
    required this.accent,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.grayMain.withValues(alpha: 0.9),
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFF2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: LayoutBuilder(
              builder: (context, constraints) => AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * (value / 3),
                decoration: BoxDecoration(
                  color: selected ? accent : AppColors.carbon,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}