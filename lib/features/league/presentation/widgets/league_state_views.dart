import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

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
          const Icon(Icons.cloud_off_rounded, size: 34, color: AppColors.grayMain),
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

/// Estado sin liga. Hero oscuro (carbon + lima) que vende la competencia y
/// una CTA para traer amigos: en vez de un aviso pasivo de "tus amigos
/// apareceran aqui", invita a compartir la app para conseguir rivales.
class LeagueEmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final VoidCallback onShareApp;

  const LeagueEmptyState({
    super.key,
    required this.onCreate,
    required this.onJoin,
    required this.onShareApp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(
          onCreate: onCreate,
          onJoin: onJoin,
        ),
        const SizedBox(height: 16),
        _ShareCard(onShareApp: onShareApp),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _HeroCard({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: BoxDecoration(
        color: AppColors.carbon,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.carbon.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.volt,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.volt.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspaces_filled,
                  size: 28,
                  color: AppColors.carbon,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aún no tienes liga',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Pero ya es hora de cambiar eso.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Una liga es tu reto de la semana: junta a tus amigos y el que acumule más reps gana el top 1 del ranking.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HeroPill(icon: Icons.group_rounded, label: 'Hasta 10'),
              _HeroPill(icon: Icons.tag_rounded, label: 'Código'),
              _HeroPill(icon: Icons.sports_gymnastics_rounded, label: 'Ranking semanal'),
              _HeroPill(icon: Icons.workspaces_outline, label: 'Reto entre amigos'),
            ],
          ),
          const SizedBox(height: 22),
          Material(
            color: AppColors.volt,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onCreate,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 20, color: AppColors.carbon),
                    SizedBox(width: 8),
                    Text(
                      'Crear mi liga',
                      style: TextStyle(
                        color: AppColors.carbon,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white24, width: 1.5),
            ),
            child: InkWell(
              onTap: onJoin,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tag_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Unirme con un código',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.glowNeutral,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.volt),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card accionable para traer amigos: compartir la app y juntar rivales, en
/// lugar de un simple aviso de que "los amigos apareceran aqui".
class _ShareCard extends StatelessWidget {
  final VoidCallback onShareApp;

  const _ShareCard({required this.onShareApp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.volt.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 22,
              color: AppColors.carbon,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Sin amigos en la app?',
                  style: TextStyle(
                    color: AppColors.carbon,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Invita a tus amigos y compitan hombro a hombro. Una liga sin rivales no es liga.',
                  style: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: AppColors.carbon,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    onTap: onShareApp,
                    borderRadius: BorderRadius.circular(13),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.share_rounded,
                            size: 16,
                            color: AppColors.volt,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Invitar a mis amigos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}