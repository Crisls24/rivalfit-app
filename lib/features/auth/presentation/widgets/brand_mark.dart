import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Unidad visual de RivalFit: cuadrado lima + rayo negro. Recurrente en
/// logo, CTAs, estados, indicadores y loaders.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        Icons.bolt,
        size: size * 0.68,
        color: Colors.black,
      ),
    );
  }
}