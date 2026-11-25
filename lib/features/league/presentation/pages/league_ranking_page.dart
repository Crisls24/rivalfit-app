import '../widgets/league_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_controller.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_providers.dart';

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
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
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
        _ =>
          state.league == null
              ? const _NoLeagueView()
              : JoinedLeagueView(state: state),
      },
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
