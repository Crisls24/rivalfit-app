import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:autohost/app/theme/app_colors.dart';

class SocialLoginCards extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final VoidCallback? onFacebookTap;

  const SocialLoginCards({
    super.key,
    this.onGoogleTap,
    this.onAppleTap,
    this.onFacebookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialCard(
          icon: const _GoogleIcon(),
          onTap: onGoogleTap,
        ),
        const SizedBox(width: 16),
        _SocialCard(
          icon: const Icon(Icons.apple, size: 24, color: Colors.white),
          onTap: onAppleTap,
        ),
        const SizedBox(width: 16),
        _SocialCard(
          icon: const _FacebookIcon(),
          onTap: onFacebookTap,
        ),
      ],
    );
  }
}

class _SocialCard extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;

  const _SocialCard({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 72,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.socialCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.socialCardBorder,
                width: 0.5,
              ),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GooglePainter(),
      ),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + radius, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          0,
          -90 * 3.14159 / 180,
          false,
        )
        ..close(),
      paint,
    );

    // Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx, center.dy - radius)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          -90 * 3.14159 / 180,
          -90 * 3.14159 / 180,
          false,
        )
        ..close(),
      paint,
    );

    // Green
    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx - radius, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          180 * 3.14159 / 180,
          -90 * 3.14159 / 180,
          false,
        )
        ..close(),
      paint,
    );

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx, center.dy + radius)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          90 * 3.14159 / 180,
          -90 * 3.14159 / 180,
          false,
        )
        ..close(),
      paint,
    );

    // White center circle
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.38, paint);

    // Blue inner arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.38),
      -30 * 3.14159 / 180,
      120 * 3.14159 / 180,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.facebook,
      size: 28,
      color: Color(0xFF1877F2),
    );
  }
}
