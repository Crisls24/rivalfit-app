import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Tarjeta base de RivalFit: panel blanco con borde sutil, esquinas de 22px y
/// sombra suave opcional.
///
/// Si se pasa [onTap] el panel es tocable (con ripple de Material). Es la
/// caja estandar de tableros, resumenes y listas de la seccion Home; evita
/// repetir el mismo [BoxDecoration] en cada widget.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final BorderRadius borderRadius;
  final bool showShadow;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.showShadow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.subtleBorder),
          boxShadow: showShadow
              ? const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}