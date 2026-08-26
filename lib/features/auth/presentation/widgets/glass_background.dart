import 'package:flutter/material.dart';
import 'package:autohost/app/theme/app_colors.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundDeep,
                AppColors.backgroundDark,
                Color(0xFF2A1045),
              ],
            ),
          ),
        ),
        // Purple glow bottom
        Positioned(
          bottom: -100,
          left: 0,
          right: 0,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 1.2,
                colors: [
                  AppColors.glowPurple.withValues(alpha: 0.25),
                  AppColors.glowPink.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Abstract geometric shapes top-left
        Positioned(
          top: 40,
          left: -20,
          child: Transform.rotate(
            angle: 0.3,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.glowPurple.withValues(alpha: 0.15),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Positioned(
          top: 80,
          left: 60,
          child: Transform.rotate(
            angle: -0.5,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.glowPink.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppColors.glowPink.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
        // Abstract triangle top-right
        Positioned(
          top: 60,
          right: 30,
          child: CustomPaint(
            size: const Size(80, 80),
            painter: _TrianglePainter(
              color: AppColors.glowPurple.withValues(alpha: 0.1),
            ),
          ),
        ),
        Positioned(
          top: 120,
          right: 80,
          child: Transform.rotate(
            angle: 0.7,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.glowPurple.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
        // Scattered small shapes
        Positioned(
          top: 200,
          left: 30,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.glowPink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Positioned(
          top: 160,
          right: 20,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.glowPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
