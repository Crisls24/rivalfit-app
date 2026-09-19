import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Avatar limpio: gradiente volt, badge de cámara (o spinner de subida) y sin
/// etiquetas redundantes debajo: la cámara ya comunica la acción.
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
    final badge = (radius * 0.62).clamp(24.0, 34.0);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.volt, Color(0xFFEAFBAF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.volt.withValues(alpha: 0.26),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: uploading ? Colors.white : AppColors.volt,
              border: Border.fromBorderSide(
                BorderSide(color: Colors.white, width: 2),
              ),
            ),
            child: uploading
                ? Padding(
                    padding: const EdgeInsets.all(7),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.carbon,
                    ),
                  )
                : Icon(
                    Icons.photo_camera,
                    color: Colors.black,
                    size: compact ? 14 : 16,
                  ),
          ),
        ],
      ),
    );
  }
}
