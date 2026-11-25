import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_controller.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_providers.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_card.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_dialogs.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_state_views.dart';

/// Acceso a la liga del usuario o a los flujos de creación e invitación.
class LeagueView extends ConsumerStatefulWidget {
  const LeagueView({super.key});

  @override
  ConsumerState<LeagueView> createState() => _LeagueViewState();
}

class _LeagueViewState extends ConsumerState<LeagueView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    // Invitacion recibida por deep link sin sesion: tras autenticarse la app
    // consume el codigo pendiente y abre la pagina de invitacion.
    final pending = ref
        .read(leagueControllerProvider.notifier)
        .consumePendingJoinCode();
    if (pending != null) {
      if (mounted) context.go('/join/$pending');
      return;
    }
    ref.read(leagueControllerProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leagueControllerProvider);

    if (state.status == LeagueStatus.loaded && state.league != null) {
      return JoinedLeagueView(state: state);
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liga',
              style: TextStyle(
                color: AppColors.carbon,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              state.league == null
                  ? 'Compite con tus amigos cada semana.'
                  : '${state.league!.name} · competencia semanal',
              style: const TextStyle(
                color: AppColors.grayMain,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            switch (state.status) {
              LeagueStatus.loading => const LeagueLoadingCard(),
              LeagueStatus.error => LeagueErrorCard(
                message: state.errorMessage ?? 'No pudimos cargar tu liga.',
                onRetry: () =>
                    ref.read(leagueControllerProvider.notifier).retry(),
              ),
              _ => LeagueEmptyState(
                onCreate: _openCreateDialog,
                onJoin: _openJoinDialog,
                onInviteFriends: () => showShareRivalFitSheet(context),
              ),
            },
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final created = await showCreateLeagueSheet(
      context,
      onCreate: (name, emoji, socialBet, photoBytes, photoFileName) => ref
          .read(leagueControllerProvider.notifier)
          .createLeague(
            name,
            emoji: emoji,
            socialBet: socialBet,
            photoBytes: photoBytes,
            photoFileName: photoFileName,
          ),
    );
    if (!mounted || created != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Liga creada')));
  }

  Future<void> _openJoinDialog() async {
    var initialCode = '';
    while (true) {
      if (!mounted) return;
      final code = await showLeagueCodeSheet(context, initialCode: initialCode);
      if (!mounted || code == null) return;
      final editCode = await context.pushNamed<bool>(
        'join',
        pathParameters: {'code': code},
      );
      if (editCode != true) return;
      initialCode = code;
    }
  }
}
