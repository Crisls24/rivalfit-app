import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/exercise/domain/models/exercise.dart';
import 'package:rivalfit/features/exercise/domain/models/training_session.dart';
import 'package:rivalfit/features/home/presentation/widgets/muscle_map_card.dart';

import '../../domain/models/league.dart';

const _heading = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w900,
  height: 1.15,
  letterSpacing: -.6,
);

extension on LeagueMember {
  // Mi progreso has no preferred group. Use confirmed reps, with a stable
  // chest/arms-first tie break matching the order of its map legend.
  MuscleGroup? get featured {
    final chest = chestArmReps ?? 0;
    final legs = legReps ?? 0;
    if (chest == 0 && legs == 0) return null;
    return chest >= legs ? MuscleGroup.chestArms : MuscleGroup.legs;
  }

  bool get hasMap => legReps != null && chestArmReps != null;
  String get groupLabel =>
      featured?.label ?? (hasMap ? 'Sin entrenar' : 'Sin datos');
  MuscleRank get rank => MuscleRank(math.max(legReps ?? 0, chestArmReps ?? 0));
}

class LeagueStandings extends StatelessWidget {
  const LeagueStandings({
    super.key,
    required this.members,
    required this.currentUserId,
  });
  final List<LeagueMember> members;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final emptyWeek = members.every((m) => m.weeklyPoints == 0);
    final winner = members.where((m) => m.dailyAward != null).firstOrNull;
    final podium = [if (members.length > 1) 1, 0, if (members.length > 2) 2];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          emptyWeek ? '¿Quién suma primero?' : 'Podio semanal',
          style: _heading,
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            gradient: const RadialGradient(
              center: Alignment(0, -.65),
              radius: 1.15,
              colors: [Color(0xff474540), Color(0xff262628), Color(0xff18181a)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: LayoutBuilder(
              builder: (context, box) {
                final height = math.min(
                  180.0,
                  (box.maxWidth / podium.length - 6) * 1.5,
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final index in podium)
                      Expanded(
                        child: _PodiumEntry(
                          member: members[index],
                          position: leaguePosition(members, index),
                          self: members[index].userId == currentUserId,
                          height: height,
                          leading:
                              !emptyWeek && leaguePosition(members, index) == 1,
                          emptyWeek: emptyWeek,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        if (winner != null && members.length > 1) _AwardCard(member: winner),
        if (members.length > 3) ...[
          const SizedBox(height: 20),
          const Text('Clasificación', style: _heading),
          const SizedBox(height: 6),
          for (var index = 3; index < members.length; index++)
            _StandingRow(
              member: members[index],
              position: leaguePosition(members, index),
              self: members[index].userId == currentUserId,
            ),
        ],
      ],
    );
  }
}

class _PodiumEntry extends StatelessWidget {
  const _PodiumEntry({
    required this.member,
    required this.position,
    required this.height,
    required this.leading,
    required this.self,
    required this.emptyWeek,
  });
  final LeagueMember member;
  final int position;
  final double height;
  final bool leading, self, emptyWeek;

  @override
  Widget build(BuildContext context) {
    final medal = emptyWeek
        ? Colors.white70
        : switch (position) {
            1 => const Color(0xffffd487),
            2 => const Color(0xffd7dbdf),
            3 => const Color(0xffe7b18e),
            _ => Colors.white70,
          };
    final textScale = MediaQuery.textScalerOf(context);
    return Semantics(
      button: true,
      label: 'Consultar a ${member.name}',
      child: InkWell(
        key: ValueKey('member-${member.userId}'),
        onTap: () => _openMember(context, member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            children: [
              Text(
                '$position.º',
                style: TextStyle(
                  color: medal,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(
                height: height,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: leading ? height : height / 1.15,
                    child: MuscleBodyMap(
                      legReps: member.legReps ?? 0,
                      chestArmReps: member.chestArmReps ?? 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: math.max(28, textScale.scale(13) * 1.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Avatar(member: member, size: 22),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: self ? AppColors.volt : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${member.weeklyPoints} pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: textScale.scale(11) * 2.6,
                child: Text(
                  member.groupLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.2,
                  ),
                  maxLines: 2,
                ),
              ),
              if (member.featured != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    member.rank.shield(17),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        member.rank.label,
                        style: TextStyle(
                          color: member.rank.finish.highlight,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member, required this.size});
  final LeagueMember member;
  final double size;
  @override
  Widget build(BuildContext context) {
    final words = member.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2);
    final initials = words.map((w) => w.characters.first.toUpperCase()).join();
    final photo = member.photoUrl?.trim();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xffe3e7dc),
      foregroundColor: AppColors.carbon,
      foregroundImage: photo == null || photo.isEmpty
          ? null
          : NetworkImage(photo),
      onForegroundImageError: photo == null || photo.isEmpty ? null : (_, _) {},
      child: Text(
        initials.isEmpty ? '?' : initials,
        textScaler: TextScaler.noScaling,
        style: TextStyle(fontSize: size * .36, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.member,
    required this.position,
    required this.self,
  });
  final LeagueMember member;
  final int position;
  final bool self;
  @override
  Widget build(BuildContext context) => Material(
    color: self ? const Color(0xffeefbc6) : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      key: ValueKey('member-${member.userId}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openMember(context, member),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 27,
              child: Text(
                '$position',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ),
            _Avatar(member: member, size: 36),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${member.name}${self ? ' · Tú' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    [
                      member.groupLabel,
                      if (member.featured != null) member.rank.label,
                    ].join(' · '),
                    style: const TextStyle(
                      color: AppColors.grayMain,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${member.weeklyPoints} pts',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AwardCard extends StatelessWidget {
  const _AwardCard({required this.member});
  final LeagueMember member;
  @override
  Widget build(BuildContext context) {
    final award = member.dailyAward!;
    final date = '${award.day.day}/${award.day.month}';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: AppColors.volt,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openMember(context, member),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${award.closed ? 'GANADOR DEL DÍA' : 'LIDERATO EN CURSO'} · $date',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Avatar(member: member, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: _heading,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${award.reps} reps confirmadas',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const Text(
                            'Más repeticiones del día',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.emoji_events_outlined, size: 40),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openMember(BuildContext context, LeagueMember member) {
  final last = member.lastSession;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheet) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Avatar(member: member, size: 42),
                const SizedBox(width: 10),
                Expanded(child: Text(member.name, style: _heading)),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(sheet),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (member.hasMap)
              MuscleMapCard(
                legReps: member.legReps!,
                chestArmReps: member.chestArmReps!,
                initialGroup: member.featured ?? MuscleGroup.legs,
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.carbon,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(12),
                child: const Column(
                  children: [
                    SizedBox(
                      height: 176,
                      child: MuscleBodyMap(legReps: 0, chestArmReps: 0),
                    ),
                    Text(
                      'Mapa muscular sin datos compartidos',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Última sesión confirmada',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            if (last != null) ...[
              Text(
                '${TrainingMovement.forId(last.exercise)?.label ?? last.exercise} · ${last.reps} reps',
              ),
              Text(
                MaterialLocalizations.of(sheet)
                    .formatShortDate(last.endedAt.toLocal()),
              ),
            ] else
              const Text(
                'Sin sesión disponible',
                style: TextStyle(color: AppColors.grayMain),
              ),
          ],
        ),
      ),
    ),
  );
}
