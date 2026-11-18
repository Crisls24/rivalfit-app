import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/exercise/domain/models/exercise.dart';
import 'package:rivalfit/features/home/presentation/widgets/progress_emblem.dart';

const _artSize = Size(1024, 1536);
const _bodyAsset = 'assets/progress/muscle-body.png';
const _groups = [MuscleGroup.chestArms, MuscleGroup.core, MuscleGroup.legs];

/// Mapa interactivo de los grupos musculares.
class MuscleMapCard extends StatefulWidget {
  const MuscleMapCard({super.key});

  @override
  State<MuscleMapCard> createState() => _MuscleMapCardState();
}

class _MuscleMapCardState extends State<MuscleMapCard> {
  MuscleGroup _selected = MuscleGroup.legs;

  void _select(MuscleGroup group) {
    if (group == _selected) return;
    setState(() => _selected = group);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF252629), Color(0xFF191A1D)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mapa muscular',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 6,
              children: [
                for (final group in _groups)
                  ChoiceChip(
                    label: Text(group.label),
                    selected: group == _selected,
                    onSelected: (_) => _select(group),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    selectedColor: AppColors.volt.withValues(alpha: 0.09),
                    backgroundColor: AppColors.glowNeutral,
                    side: BorderSide(
                      color: group == _selected
                          ? AppColors.volt
                          : AppColors.glassBorder,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: group == _selected ? AppColors.volt : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: AspectRatio(
                  aspectRatio: _artSize.aspectRatio,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest;
                      return GestureDetector(
                        excludeFromSemantics: true,
                        onTapUp: (details) {
                          final position =
                              details.localPosition /
                              size.width *
                              _artSize.width;
                          for (final group in _groups) {
                            if (_bodyRegions[group]!.contains(position)) {
                              _select(group);
                              break;
                            }
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const _MuscleBody(),
                            RepaintBoundary(
                              child: CustomPaint(
                                painter: _MuscleOutline(_selected),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _MuscleDetail(group: _selected),
          ],
        ),
      ),
    );
  }
}

class _MuscleBody extends StatelessWidget {
  const _MuscleBody();

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pixelWidth = math.min(
            _artSize.width.toInt(),
            math.max(1, (constraints.maxWidth * pixelRatio).ceil()),
          );
          return Image.asset(
            _bodyAsset,
            fit: BoxFit.contain,
            cacheWidth: pixelWidth,
          );
        },
      ),
    );
  }
}

class _MuscleDetail extends StatelessWidget {
  final MuscleGroup group;

  const _MuscleDetail({required this.group});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            const ProgressEmblem(
              icon: Icons.star_outline_rounded,
              finish: ProgressEmblemFinish.steel,
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Sin entrenar',
                    style: TextStyle(color: AppColors.textGray, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '0 reps verificadas',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: 0,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.volt,
                    backgroundColor: AppColors.glassBorder,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '1 rep para Bronce',
                    style: TextStyle(color: AppColors.textGray, fontSize: 11),
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

class _MuscleOutline extends CustomPainter {
  final MuscleGroup group;

  const _MuscleOutline(this.group);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _scaledRegion(group, size),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.5
        ..color = AppColors.volt,
    );
  }

  @override
  bool shouldRepaint(_MuscleOutline oldDelegate) => group != oldDelegate.group;
}

Path _scaledRegion(MuscleGroup group, Size size) {
  final scale = size.width / _artSize.width;
  return _bodyRegions[group]!.transform(
    (Matrix4.diagonal3Values(scale, scale, 1)).storage,
  );
}

// Coordinates follow the source image. The same paths drive clipping, the
// selection outline and hit testing.
final _bodyRegions = {
  MuscleGroup.legs: _bilateral(
    Path()
      ..moveTo(357, 771)
      ..cubicTo(397, 779, 459, 827, 499, 861)
      ..cubicTo(485, 925, 460, 972, 449, 1016)
      ..cubicTo(440, 1050, 432, 1076, 422, 1097)
      ..cubicTo(432, 1145, 448, 1197, 408, 1242)
      ..cubicTo(393, 1281, 382, 1327, 380, 1359)
      ..quadraticBezierTo(354, 1351, 330, 1358)
      ..cubicTo(335, 1294, 318, 1232, 313, 1184)
      ..cubicTo(306, 1127, 332, 1096, 344, 1068)
      ..cubicTo(341, 1031, 351, 1015, 342, 988)
      ..cubicTo(313, 925, 328, 851, 357, 771)
      ..close(),
  ),
  MuscleGroup.core: Path()
    ..moveTo(383, 429)
    ..cubicTo(429, 451, 472, 446, 512, 430)
    ..cubicTo(552, 446, 595, 451, 641, 429)
    ..cubicTo(654, 490, 617, 532, 625, 582)
    ..quadraticBezierTo(633, 615, 622, 638)
    ..cubicTo(565, 672, 460, 675, 402, 638)
    ..quadraticBezierTo(391, 615, 399, 582)
    ..cubicTo(407, 532, 370, 490, 383, 429)
    ..close(),
  MuscleGroup.chestArms: _bilateral(
    Path()
      ..moveTo(512, 316)
      ..cubicTo(486, 285, 449, 297, 416, 299)
      ..cubicTo(339, 265, 262, 315, 278, 413)
      ..cubicTo(253, 448, 263, 490, 249, 526)
      ..cubicTo(197, 566, 208, 659, 173, 731)
      ..quadraticBezierTo(192, 733, 219, 751)
      ..cubicTo(244, 689, 299, 650, 314, 590)
      ..cubicTo(323, 532, 356, 500, 362, 426)
      ..quadraticBezierTo(365, 409, 380, 429)
      ..cubicTo(421, 452, 474, 443, 512, 426)
      ..close(),
  ),
};

Path _bilateral(Path left) => Path()
  ..addPath(left, Offset.zero)
  ..addPath(
    left.transform(
      (Matrix4.translationValues(
        _artSize.width,
        0,
        0,
      )..scaleByDouble(-1, 1, 1, 1)).storage,
    ),
    Offset.zero,
  );
