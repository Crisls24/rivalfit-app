import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Boton principal solido con texto en negrita. Por defecto Neón Voltio,
/// pero puede configurarse (ej. Negro Carbón con texto blanco).
class VoltButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final Color glowColor;

  const VoltButton({
    super.key,
    required this.text,
    this.isLoading = false,
    this.onPressed,
    this.backgroundColor = AppColors.volt,
    this.textColor = Colors.black,
    this.icon,
    this.glowColor = AppColors.volt,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final contentColor = enabled ? textColor : Colors.black.withValues(alpha: 0.25);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled && glowColor != AppColors.volt
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
      color: enabled ? backgroundColor : AppColors.subtleBorder,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 54,
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: contentColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text.toUpperCase(),
                        style: TextStyle(
                          color: contentColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 10),
                        Icon(icon, size: 18, color: contentColor),
                      ],
                    ],
                  ),
          ),
        ),
      ),
      ),
    );
  }
}