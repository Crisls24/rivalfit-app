import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';
import 'package:rivalfit/features/league/presentation/widgets/member_tile.dart';

/// Card principal de la liga ya creada: cabecera con codigo, top 5 de la
/// clasificacion, invitacion (o aviso de liga completa) y preview de amigos.
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LeagueHeader(league: league, isFull: _isFull, onLeave: onLeave),
          const SizedBox(height: 16),
          Divider(color: AppColors.subtleBorder.withValues(alpha: 0.8)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clasificación',
                style: TextStyle(
                  color: AppColors.carbon,
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
                      color: AppColors.carbon,
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
                  color: AppColors.grayMain.withValues(alpha: 0.85),
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
          if (_isFull)
            const _FullBadge()
          else
            _InviteButton(onTap: onInvite),
          const SizedBox(height: 18),
          Divider(color: AppColors.subtleBorder.withValues(alpha: 0.8)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AMIGOS',
                style: TextStyle(
                  color: AppColors.carbon,
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
                      color: AppColors.carbon,
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
          _FriendsPreview(members: ranking.take(3).toList(), onInvite: onInvite),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: onLeave,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

  const _LeagueHeader({
    required this.league,
    required this.isFull,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.volt.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              league.emoji,
              style: const TextStyle(fontSize: 24),
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
                  color: AppColors.carbon,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              _CodeChip(code: league.code),
            ],
          ),
        ),
        if (isFull)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
        const SizedBox(width: 6),
        IconButton(
          onPressed: onLeave,
          tooltip: 'Salir de la liga',
          icon: const Icon(
            Icons.logout_rounded,
            size: 20,
            color: AppColors.grayMain,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Código $code copiado')),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.panelSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Código $code',
              style: const TextStyle(
                color: AppColors.grayMain,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.copy_rounded,
              size: 12,
              color: AppColors.grayMain,
            ),
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
      color: AppColors.carbon,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_alt_1_rounded,
                  size: 18, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Invitar amigos',
                style: TextStyle(
                  color: Colors.white,
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
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block_rounded,
            size: 18,
            color: AppColors.grayMain.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          Text(
            'Liga completa · espera la próxima semana',
            style: TextStyle(
              color: AppColors.grayMain.withValues(alpha: 0.9),
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
          color: AppColors.grayMain.withValues(alpha: 0.8),
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
                  color: AppColors.grayMain,
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
        color: AppColors.avatarBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: photo != null && photo.isNotEmpty
                  ? Image.network(photo, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        initialsFor(member.displayName)[0],
                        style: const TextStyle(
                          color: AppColors.carbon,
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
              color: AppColors.carbon,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}