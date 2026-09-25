import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_dialogs.dart';
import 'package:rivalfit/features/league/presentation/widgets/member_tile.dart';

/// Card principal de la liga ya creada: cabecera con icono, codigo y apuesta,
/// top 5 de la clasificacion, invitacion y preview de amigos.
class LeagueCard extends StatelessWidget {
  final League league;
  final List<LeagueMember> ranking;
  final String? currentUserId;
  final VoidCallback onInvite;
  final VoidCallback onOpenRanking;
  final VoidCallback onLeave;

  const LeagueCard({
    super.key,
    required this.league,
    required this.ranking,
    required this.currentUserId,
    required this.onInvite,
    required this.onOpenRanking,
    required this.onLeave,
  });

  bool get _isFull => ranking.length >= league.maxMembers;

  @override
  Widget build(BuildContext context) {
    final hasSocialBet = (league.socialBet ?? '').trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171717), Color(0xFF0D0D0D)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.volt.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LeagueHeader(
            league: league,
            isFull: _isFull,
            onLeave: onLeave,
            hasSocialBet: hasSocialBet,
          ),
          if (hasSocialBet) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.volt.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.volt.withValues(alpha: 0.25),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.whatshot_rounded,
                    size: 14,
                    color: AppColors.volt,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      league.socialBet!,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clasificación',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              InkWell(
                onTap: onOpenRanking,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: Text(
                    'VER CLASIFICACIÓN  →',
                    style: TextStyle(
                      color: AppColors.volt,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (ranking.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Aún no hay repeticiones esta semana. ¡Invita a tus amigos!',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...List.generate(
              ranking.length.clamp(0, 5),
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: MemberTile(
                  member: ranking[i],
                  position: i + 1,
                  isSelf: ranking[i].userId == currentUserId,
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (_isFull) const _FullBadge() else _InviteButton(onTap: onInvite),
          const SizedBox(height: 18),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AMIGOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              InkWell(
                onTap: onOpenRanking,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: Text(
                    'VER TODOS  →',
                    style: TextStyle(
                      color: AppColors.volt,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FriendsPreview(
            members: ranking.take(3).toList(),
            onInvite: onInvite,
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: onLeave,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textGray,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                textStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Salir de la liga'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueHeader extends StatelessWidget {
  final League league;
  final bool isFull;
  final VoidCallback onLeave;
  final bool hasSocialBet;

  const _LeagueHeader({
    required this.league,
    required this.isFull,
    required this.onLeave,
    required this.hasSocialBet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.volt.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.volt.withValues(alpha: 0.28)),
          ),
          child: Center(
            child: Icon(
              leagueIconData(league.iconText),
              size: 22,
              color: AppColors.volt,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                league.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              _CodeChip(code: league.code),
            ],
          ),
        ),
        if (isFull)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.volt.withValues(alpha: 0.9),
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
          )
        else if (!hasSocialBet)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: const Text(
              'SEMANAL',
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        const SizedBox(width: 6),
        IconButton(
          onPressed: onLeave,
          tooltip: 'Salir de la liga',
          icon: const Icon(
            Icons.logout_rounded,
            size: 20,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }
}

class _CodeChip extends StatelessWidget {
  final String code;

  const _CodeChip({required this.code});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Código $code copiado')));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Código $code',
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.copy_rounded, size: 12, color: AppColors.textGray),
          ],
        ),
      ),
    );
  }
}

class _InviteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _InviteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.volt,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_add_alt_1_rounded,
                size: 18,
                color: AppColors.carbon,
              ),
              const SizedBox(width: 8),
              const Text(
                'Invitar amigos',
                style: TextStyle(
                  color: AppColors.carbon,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullBadge extends StatelessWidget {
  const _FullBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block_rounded, size: 18, color: AppColors.textGray),
          const SizedBox(width: 8),
          Text(
            'Liga completa · espera la próxima semana',
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsPreview extends StatelessWidget {
  final List<LeagueMember> members;
  final VoidCallback onInvite;

  const _FriendsPreview({required this.members, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Text(
        'Invita a tus amigos para llenar la liga.',
        style: TextStyle(
          color: AppColors.textGray,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final member in members) _FriendPill(member: member),
        if (members.length < 3)
          Padding(
            padding: const EdgeInsets.all(4),
            child: InkWell(
              onTap: onInvite,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: 20,
                  color: AppColors.textGray,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FriendPill extends StatelessWidget {
  final LeagueMember member;

  const _FriendPill({required this.member});

  @override
  Widget build(BuildContext context) {
    final photo = member.photoUrl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.backgroundDark,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: photo != null && photo.isNotEmpty
                  ? Image.network(photo, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        initialsFor(member.displayName)[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '@${member.alias ?? member.displayName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
