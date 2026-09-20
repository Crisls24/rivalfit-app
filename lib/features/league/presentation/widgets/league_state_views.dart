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

/// Estado sin liga (cuenta nueva). El hero oscuro funciona como la sala de
/// espera de la liga: emblema, "El primer puesto te espera", contador 0 / 10,
/// espacios vacios por cubrir y las dos acciones (crear / unirse). Debajo, un
/// link discreto permite invitar amigos a la app mientras se forma el clan;
/// compartir el codigo cobra peso recien cuando ya existe la liga.
///
/// Identidad: pertenencia + competencia. "Clan" como grupo de amigos que se
/// reune a competir, sin estetica de videojuego.
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(onCreate: onCreate, onJoin: onJoin),
        const SizedBox(height: 16),
        // Link discreto: invita a la app sin ruido visual.
        Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onInviteFriends,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 16,
                      color: AppColors.carbon,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Invita a tus amigos',
                      style: TextStyle(
                        color: AppColors.carbon,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '›',
                      style: TextStyle(
                        color: AppColors.grayMain,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Arena oscura: composicion centrada que une identidad de liga (emblema),
/// sensacion de competencia por comenzar (contador + espacios vacios) y las
/// dos acciones posibles. Sin chips ni explicaciones extra.
class _HeroCard extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _HeroCard({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.carbon,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.carbon.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Identidad de la sala de espera: emblema de liga contenido.
          const LeagueEmblem(size: 76),
          const SizedBox(height: 22),
          const Text(
            'EL PRIMER PUESTO\nTE ESPERA',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.volt.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '0 / 10 competidores',
              style: TextStyle(
                color: AppColors.volt,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Crea tu liga y reúne a tus rivales.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          // Sala de espera: posiciones vacias que llenara la competencia.
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CompetitorSlot(),
              SizedBox(width: 16),
              _CompetitorSlot(),
              SizedBox(width: 16),
              _CompetitorSlot(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Espacios esperando a tus rivales',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 26),
          // Accion principal: crear liga.
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
          const SizedBox(height: 14),
          // Accion secundaria: unirse por invitacion. Boton sutil a lo ancho,
          // con menos peso visual que el volt: solo borde y texto centrado.
          Text(
            '¿Ya tienes una invitación?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onJoin,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  'Unirme a una liga',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
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

/// Posicion vacia del podio: una silueta en difuminado que espera a un
/// competidor. El mismo slot se reutilizara para el ranking con rivales.
class _CompetitorSlot extends StatelessWidget {
  const _CompetitorSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.2,
        ),
      ),
      child: Icon(
        Icons.person_outline_rounded,
        size: 19,
        color: Colors.white.withValues(alpha: 0.22),
      ),
    );
  }
}