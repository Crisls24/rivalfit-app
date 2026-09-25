import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_controller.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_providers.dart';
import 'package:rivalfit/features/league/presentation/widgets/invite_sheet.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_card.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_dialogs.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_state_views.dart';
import 'package:share_plus/share_plus.dart';

/// Tab "Liga": compite contra tus amigos y demuestra tu disciplina. Sin liga
/// muestra la accion de crear/unirse; con liga muestra la clasificacion top 5,
/// el enlace de invitacion (o el aviso de liga completa) y el preview.
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
                  ? 'Compite contra tus amigos. Demuestra tu disciplina.'
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
              _ =>
                state.league == null
                    ? LeagueEmptyState(
                        onCreate: _openCreateDialog,
                        onJoin: _openJoinDialog,
                        onInviteFriends: _shareApp,
                      )
                    : LeagueCard(
                        league: state.league!,
                        ranking: state.ranking,
                        currentUserId: ref
                            .watch(authControllerProvider)
                            .user
                            ?.id,
                        onInvite: () => showInviteSheet(context, state.league!),
                        onOpenRanking: () => context.push('/league/ranking'),
                        onLeave: _confirmLeave,
                      ),
            },
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final hadLeague = ref.read(leagueControllerProvider).league != null;
    await showCreateLeagueSheet(
      context,
      initialName: ref.watch(authControllerProvider).user?.displayName ?? '',
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
    if (!mounted) return;
    final league = ref.read(leagueControllerProvider).league;
    if (!hadLeague && league != null) {
      await showLeagueCreatedDialog(
        context,
        league: league,
        onInvite: () => showInviteSheet(context, league),
      );
    }
  }

  Future<void> _openJoinDialog() async {
    final hadLeague = ref.read(leagueControllerProvider).league != null;
    await showJoinLeagueDialog(
      context,
      onSubmit: (code) =>
          ref.read(leagueControllerProvider.notifier).join(code),
    );
    if (!mounted) return;
    final league = ref.read(leagueControllerProvider).league;
    if (!hadLeague && league != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('¡Bienvenido a ${league.name}!')));
    }
  }

  Future<void> _shareApp() async {
    // Sin liga aun no hay codigo que compartir: invita a la app mientras se
    // forma el clan. Con liga, la invitacion con codigo vive en el invite sheet.
    // El enlace va solo en la ultima linea para que WhatsApp arme el preview
    // con el sitio oficial.
    const message =
        'Me estoy entrenando en serio con RivalFit.\n'
        'Voy a armar mi clan y competir cada semana.\n'
        '\n'
        '¿Te apuntas?\n'
        '\n'
        'https://rivalfit.iscx.site/#descargar';
    await SharePlus.instance.share(ShareParams(text: message));
  }

  Future<void> _confirmLeave() async {
    final league = ref.read(leagueControllerProvider).league;
    if (league == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Salir de la liga?',
          style: TextStyle(
            color: AppColors.carbon,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'Perderás tu lugar en "${league.name}". Podrás volver solo con un nuevo código de invitación.',
          style: const TextStyle(
            color: AppColors.grayMain,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.grayMain,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Salir',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await ref.read(leagueControllerProvider.notifier).leave();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Saliste de la liga')));
  }
}
