import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_controller.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_providers.dart';
import 'package:rivalfit/features/league/presentation/widgets/member_tile.dart';

/// Clasificacion completa de la liga (hasta 10 miembros). Se abre desde la tab
/// Liga; usa el estado del [leagueControllerProvider] compartido, asi que no
/// necesita llamadas propias si la tab ya cargo.
class LeagueRankingPage extends ConsumerStatefulWidget {
  const LeagueRankingPage({super.key});

  @override
  ConsumerState<LeagueRankingPage> createState() => _LeagueRankingPageState();
}

class _LeagueRankingPageState extends ConsumerState<LeagueRankingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(leagueControllerProvider.notifier);
      final status = ref.read(leagueControllerProvider).status;
      if (status != LeagueStatus.loaded) controller.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leagueControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(
        backgroundColor: AppColors.iceBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.carbon),
        title: const Text(
          'Clasificación',
          style: TextStyle(
            color: AppColors.carbon,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: false,
      ),
      body: switch (state.status) {
        LeagueStatus.loading => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.carbon,
              backgroundColor: AppColors.panelSoft,
            ),
          ),
        LeagueStatus.error => _ErrorView(message: state.errorMessage ?? ''),
        _ => state.league == null
            ? const _NoLeagueView()
            : _RankingList(
                league: state.league!,
                ranking: state.ranking,
                currentUserId:
                    ref.watch(authControllerProvider).user?.id,
              ),
      },
    );
  }
}

class _RankingList extends StatelessWidget {
  final League league;
  final List<LeagueMember> ranking;
  final String? currentUserId;

  const _RankingList({
    required this.league,
    required this.ranking,
    required this.currentUserId,
  });

  bool get _isFull => ranking.length >= league.maxMembers;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    league.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      league.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.carbon,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${ranking.length}/${league.maxMembers} integrantes',
                      style: TextStyle(
                        color: AppColors.grayMain.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isFull)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.volt.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'COMPLETA',
                    style: TextStyle(
                      color: AppColors.carbon,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Esta semana',
          style: TextStyle(
            color: AppColors.carbon.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        if (ranking.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Aún no hay puntos esta semana. ¡Haz tu primer entrenamiento!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grayMain.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          )
        else
          for (var i = 0; i < ranking.length; i++)
            MemberTile(
              member: ranking[i],
              position: i + 1,
              isSelf: ranking[i].userId == currentUserId,
            ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: AppColors.grayMain,
            ),
            const SizedBox(height: 14),
            Text(
              message.isEmpty ? 'No pudimos cargar la clasificación.' : message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.carbon,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoLeagueView extends StatelessWidget {
  const _NoLeagueView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.workspaces_outline,
              size: 42,
              color: AppColors.grayMain,
            ),
            const SizedBox(height: 14),
            const Text(
              'No estás en ninguna liga',
              style: TextStyle(
                color: AppColors.carbon,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Material(
              color: AppColors.carbon,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  child: Text(
                    'Volver',
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
      ),
    );
  }
}