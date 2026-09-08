import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Avatar: fondo gris claro, borde negro fino y badge de acento (punto de estado).
class AvatarSelector extends StatelessWidget {
  final ImageProvider? image;
  final String initials;
  final bool uploading;
  final VoidCallback onTap;
  final double radius;

  const AvatarSelector({
    super.key,
    required this.image,
    required this.initials,
    required this.uploading,
    required this.onTap,
    this.radius = 54,
  });

  @override
  Widget build(BuildContext context) {
    final compact = radius < 50;
    final badge = (radius * 0.63).clamp(24.0, 34.0);
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.carbon, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: radius,
                  backgroundColor: AppColors.avatarBackground,
                  backgroundImage: image,
                  child: image == null
                      ? Text(
                          initials,
                          style: TextStyle(
                            color: AppColors.carbon,
                            fontSize: compact ? 22 : 32,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
              ),
              Container(
                width: badge,
                height: badge,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.volt,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                child: Icon(
                  Icons.photo_camera,
                  color: Colors.black,
                  size: compact ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (uploading)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.carbon,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Subiendo foto...',
                style: TextStyle(color: AppColors.grayMain, fontSize: 12),
              ),
            ],
          )
        else
          const Text(
            'Toca para cambiar tu foto',
            style: TextStyle(color: AppColors.grayMain, fontSize: 12),
          ),
      ],
    );
  }
}