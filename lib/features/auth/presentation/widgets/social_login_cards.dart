import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        if (Platform.isIOS) ...[
          const SizedBox(width: 16),
          _SocialCard(
            icon: const Icon(Icons.apple, size: 24, color: Colors.white),
            onTap: onAppleTap,
          ),
        ],
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
    return SvgPicture.asset(
      'assets/icons/google.svg',
      width: 22,
      height: 22,
    );
  }
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
