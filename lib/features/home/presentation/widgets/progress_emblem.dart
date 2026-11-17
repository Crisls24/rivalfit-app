import 'package:flutter/material.dart';

enum ProgressEmblemFinish {
  volt(Color(0xFFE8FFAB), Color(0xFF9ECC37), Color(0xFF31421D)),
  steel(Color(0xFFE1E6EC), Color(0xFF8791A1), Color(0xFF353D49)),
  bronze(Color(0xFFFFDFB6), Color(0xFFD79258), Color(0xFF6D351D));

  const ProgressEmblemFinish(this.highlight, this.midtone, this.shadow);

  final Color highlight;
  final Color midtone;
  final Color shadow;
}

class ProgressEmblem extends StatelessWidget {
  const ProgressEmblem({
    super.key,
    required this.icon,
    required this.finish,
    required this.size,
    this.medallion = false,
  });

  final IconData icon;
  final ProgressEmblemFinish finish;
  final double size;
  final bool medallion;

  @override
  Widget build(BuildContext context) {
    final frame = medallion ? Icons.circle : Icons.shield_rounded;
    final rim = medallion ? Icons.circle_outlined : Icons.shield_outlined;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [finish.highlight, finish.midtone, finish.shadow],
                stops: const [0.12, 0.45, 0.9],
              ).createShader(bounds),
              child: Icon(frame, color: Colors.white, size: size),
            ),
            Icon(frame, size: size * 0.79, color: finish.shadow),
            Icon(
              rim,
              size: size * 0.76,
              color: finish.highlight.withValues(alpha: 0.52),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: medallion ? 0 : size * 0.06),
              child: Icon(icon, size: size * 0.46, color: finish.highlight),
            ),
          ],
        ),
      ),
    );
  }
}
