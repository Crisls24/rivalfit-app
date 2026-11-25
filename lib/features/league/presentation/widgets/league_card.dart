import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rivalfit/features/exercise/domain/models/saved_training_session.dart';
import 'package:rivalfit/features/exercise/presentation/controllers/training_storage_providers.dart';
import 'package:rivalfit/features/home/presentation/training_progress.dart';

import '../../domain/models/league.dart';
import '../controllers/league_controller.dart';
import '../controllers/league_providers.dart';
import 'invite_sheet.dart';
import 'league_emblem_icon.dart';
import 'league_standings.dart';
import 'league_training_action.dart';

class JoinedLeagueView extends ConsumerWidget {
  const JoinedLeagueView({super.key, required this.state});
  final LeagueState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final league = state.league!;
    final currentId = ref.watch(authControllerProvider).user?.id;
    final controller = ref.read(leagueControllerProvider.notifier);
    final roster = state.ranking;
    final full =
        roster.length >= league.maxMembers ||
        league.memberCount >= league.maxMembers;
    final solo = roster.length == 1 && !full;
    final canInvite = !full && (roster.isNotEmpty || league.memberCount > 0);
    void invite() => showInviteSheet(context, league);

    // On older servers only the signed-in member has confirmed history available.
    var members = roster;
    if (currentId != null &&
        roster.any((m) => m.userId == currentId && m.legReps == null)) {
      final sessions = ref.watch(savedTrainingSessionsProvider).valueOrNull;
      if (sessions != null) {
        final mine =
            sessions
                .where(
                  (s) =>
                      s.ownerId == currentId &&
                      s.state == SavedSessionState.confirmed &&
                      s.result.eligibleForSubmission,
                )
                .toList()
              ..sort(
                (a, b) => b.result.endedAtUtc.compareTo(a.result.endedAtUtc),
              );
        final progress = TrainingProgress.fromSessions(mine);
        final last = mine.firstOrNull?.result;
        members = [
          for (final m in roster)
            if (m.userId != currentId)
              m
            else
              LeagueMember(
                userId: m.userId,
                displayName: m.displayName,
                alias: m.alias,
                photoUrl: m.photoUrl,
                joinedAt: m.joinedAt,
                weeklyPoints: m.weeklyPoints,
                position: m.position,
                legReps: progress.legReps,
                chestArmReps: progress.chestArmReps,
                lastSession: last == null
                    ? null
                    : (
                        exercise: last.exerciseId,
                        reps: last.validReps,
                        endedAt: last.endedAtUtc,
                      ),
              ),
        ];
      }
    }

    final light = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.volt,
        surface: AppColors.base,
      ),
      textTheme: Theme.of(context).textTheme
          .apply(bodyColor: AppColors.carbon, displayColor: AppColors.carbon),
    );
    return Theme(
      data: light,
      child: Material(
        color: AppColors.base,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: controller.loadRanking,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              children: [
                const Text(
                  'RivalFit',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    LeagueBadge(
                      size: 52,
                      photoUrl: league.photoUrl,
                      background: AppColors.carbon,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            league.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          if (league.socialBet?.trim().isNotEmpty == true)
                            Text(
                              league.socialBet!,
                              style: const TextStyle(color: AppColors.grayMain),
                            ),
                        ],
                      ),
                    ),
                    if (canInvite && !solo)
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.volt,
                          foregroundColor: AppColors.carbon,
                        ),
                        tooltip: 'Invitar amigos',
                        onPressed: invite,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                      ),
                    PopupMenuButton<String>(
                      tooltip: 'Opciones de la liga',
                      onSelected: (value) async {
                        if (value == 'leave') {
                          await _confirmLeave(context, ref);
                          return;
                        }
                        await Clipboard.setData(
                          ClipboardData(text: league.code),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Código ${league.code} copiado'),
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'code',
                          child: Text('Copiar código · ${league.code}'),
                        ),
                        const PopupMenuItem(
                          value: 'leave',
                          child: Text('Salir de la liga'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (solo)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.volt,
                        foregroundColor: AppColors.carbon,
                      ),
                      onPressed: invite,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Invitar amigos'),
                    ),
                  ),
                if (full)
                  const Text(
                    'Liga completa',
                    style: TextStyle(color: AppColors.grayMain),
                  ),
                if (state.photoError != null)
                  TextButton(
                    onPressed: controller.retryPhoto,
                    child: Text('${state.photoError} Reintentar foto'),
                  ),
                if (state.rankingError != null)
                  TextButton(
                    onPressed: controller.loadRanking,
                    child: Text(
                      '${state.rankingError} Reintentar clasificación',
                    ),
                  ),
                if (state.rankingLoading && roster.isEmpty)
                  const LinearProgressIndicator(),
                if (members.isNotEmpty)
                  LeagueStandings(members: members, currentUserId: currentId)
                else if (!state.rankingLoading && state.rankingError == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Clasificación sin integrantes disponibles.'),
                  ),
                const SizedBox(height: 16),
                const LeagueTrainingAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
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
    if (confirmed != true || !context.mounted) return;
    final error = await ref.read(leagueControllerProvider.notifier).leave();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Saliste de la liga')));
  }
}
