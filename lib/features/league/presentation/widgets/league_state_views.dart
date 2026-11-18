import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_emblem_icon.dart';

/// Tarjeta de carga mientras se consulta la liga.
class LeagueLoadingCard extends StatelessWidget {
  const LeagueLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.carbon,
            backgroundColor: AppColors.panelSoft,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de error de red con boton de reintento.
class LeagueErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const LeagueErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 34,
            color: AppColors.grayMain,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.carbon,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: AppColors.carbon,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                child: Text(
                  'Reintentar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Entrada a la competencia para quien aún no pertenece a una liga.
class LeagueEmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final VoidCallback onInviteFriends;

  const LeagueEmptyState({
    super.key,
    required this.onCreate,
    required this.onJoin,
    required this.onInviteFriends,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ColoredBox(
            color: AppColors.carbon,
            child: Stack(
              children: [
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: CustomPaint(
                      size: Size(138, 107),
                      painter: _PodiumOutline(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Align(
                        alignment: Alignment.centerRight,
                        child: LeagueEmblem(size: 46),
                      ),
                      const Text(
                        'Crea tu liga',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Hasta 10 integrantes',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: onCreate,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.volt,
                          foregroundColor: AppColors.carbon,
                          minimumSize: const Size(140, 46),
                        ),
                        child: const Text('Crear liga'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _LeagueActionRow(title: 'Tengo un código', onTap: onJoin),
        const SizedBox(height: 8),
        _LeagueActionRow(
          title: 'Compartir RivalFit',
          subtitle: 'Envía el enlace de descarga',
          icon: Icons.share_outlined,
          onTap: onInviteFriends,
        ),
      ],
    );
  }
}

class _LeagueActionRow extends StatelessWidget {
  const _LeagueActionRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.subtleBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: onTap,
        leading: icon == null
            ? null
            : Icon(icon, color: AppColors.carbon, size: 21),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.carbon,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: const TextStyle(color: AppColors.grayMain, fontSize: 12),
              ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.carbon,
        ),
      ),
    );
  }
}

class _PodiumOutline extends CustomPainter {
  const _PodiumOutline();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Offset.zero & size);
    for (final (left, height) in [
      (10.0, 35.0),
      (41.0, 69.0),
      (72.0, 92.0),
      (103.0, 56.0),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - height, 35, height + 10),
          const Radius.circular(9),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PodiumOutline oldDelegate) => false;
}
