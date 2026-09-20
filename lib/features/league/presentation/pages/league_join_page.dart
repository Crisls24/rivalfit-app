import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_providers.dart';

/// Pagina que abre el enlace de invitacion (com.rivalfit.rivalfit://join/CODE
/// o https://fit-api.iscx.site/join/CODE). Muestra "TE HAN INVITADO" con el
/// nombre de la liga y permite unirse con UN SOLO toque.
class LeagueJoinPage extends ConsumerStatefulWidget {
  final String code;

  const LeagueJoinPage({super.key, required this.code});

  @override
  ConsumerState<LeagueJoinPage> createState() => _LeagueJoinPageState();
}

class _LeagueJoinPageState extends ConsumerState<LeagueJoinPage> {
  League? _league;
  bool? _alreadyMember;
  String? _error;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = ref.read(leagueRepositoryProvider);
    final myLeague = await repo.getMyLeague();
    final found = await repo.findByCode(widget.code);
    if (!mounted) return;

    if (found.error != null) {
      setState(() => _error = found.error!.message);
      return;
    }
    setState(() {
      _league = found.league;
      _alreadyMember = myLeague.league != null &&
          myLeague.league!.id == found.league?.id;
    });
  }

  Future<void> _join() async {
    if (_joining) return;
    setState(() => _joining = true);
    final error =
        await ref.read(leagueControllerProvider.notifier).join(widget.code);
    ref.read(leagueControllerProvider.notifier).consumePendingJoinCode();
    if (!mounted) return;
    if (error != null) {
      setState(() => _joining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    context.go('/home');
    messenger.showSnackBar(
      SnackBar(content: Text('¡Te uniste a ${_league?.name ?? 'la liga'}!')),
    );
  }

  void _dismiss() {
    ref.read(leagueControllerProvider.notifier).consumePendingJoinCode();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null) {
      body = _ResultView(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.danger,
        title: 'Código no válido',
        message: _error!,
        actionLabel: 'Ir a inicio',
        onAction: _dismiss,
      );
    } else if (_league == null || _alreadyMember == null) {
      body = const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.carbon,
          backgroundColor: AppColors.panelSoft,
        ),
      );
    } else if (_alreadyMember!) {
      final league = _league!;
      body = _ResultView(
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.success,
        title: 'Ya eres parte de esta liga',
        message:
            '"${league.name}" · ${league.memberCount}/${league.maxMembers} integrantes.',
        actionLabel: 'Ver mi liga',
        onAction: _dismiss,
      );
    } else {
      body = _InviteView(
        league: _league!,
        joining: _joining,
        onJoin: _join,
        onDismiss: _dismiss,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: body,
        ),
      ),
    );
  }
}

class _InviteView extends StatelessWidget {
  final League league;
  final bool joining;
  final VoidCallback onJoin;
  final VoidCallback onDismiss;

  const _InviteView({
    required this.league,
    required this.joining,
    required this.onJoin,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.volt.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.volt.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  league.emoji,
                  style: const TextStyle(fontSize: 38),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'TE HAN INVITADO',
              style: TextStyle(
                color: AppColors.carbon,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              league.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.carbon,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${league.memberCount}/${league.maxMembers} integrantes listos para competir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grayMain.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.subtleBorder),
              ),
              child: Text(
                'Código ${league.code}',
                style: const TextStyle(
                  color: AppColors.grayMain,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Material(
              color: AppColors.volt,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: joining ? null : onJoin,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: joining
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.carbon,
                            ),
                          )
                        : const Text(
                            'Unirme a la liga',
                            style: TextStyle(
                              color: AppColors.carbon,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: joining ? null : onDismiss,
              child: const Text(
                'Ahora no',
                style: TextStyle(
                  color: AppColors.grayMain,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _ResultView({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 58, color: iconColor),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.carbon,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grayMain.withValues(alpha: 0.85),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          Material(
            color: AppColors.carbon,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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