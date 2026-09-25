import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';

/// Fila de la clasificacion. La posicion del usuario autenticado se resalta
/// con tint Volt para que el jugador se encuentre rapido en el ranking.
class MemberTile extends StatelessWidget {
  final LeagueMember member;
  final int position;
  final bool isSelf;

  const MemberTile({
    super.key,
    required this.member,
    required this.position,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelf
            ? AppColors.volt.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelf
              ? AppColors.volt.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          _PositionBadge(position: position),
          const SizedBox(width: 12),
          _TileAvatar(member: member, isSelf: isSelf),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSelf ? 'Tú' : '@${member.alias ?? member.displayName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isSelf ? FontWeight.w900 : FontWeight.w800,
                  ),
                ),
                if (!isSelf) ...[
                  const SizedBox(height: 1),
                  Text(
                    member.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textGray,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${member.weeklyPoints} pts',
            style: TextStyle(
              color: isSelf ? AppColors.volt : Colors.white,
              fontSize: 12,
              fontWeight: isSelf ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final int position;

  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    final isPodium = position <= 3;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isPodium ? AppColors.volt : Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$position',
        style: TextStyle(
          color: isPodium ? AppColors.carbon : Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TileAvatar extends StatelessWidget {
  final LeagueMember member;
  final bool isSelf;

  const _TileAvatar({required this.member, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    final photo = member.photoUrl;
    final name = member.displayName;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelf ? AppColors.volt : Colors.white.withValues(alpha: 0.14),
          width: isSelf ? 2 : 1,
        ),
      ),
      child: ClipOval(
        child: photo != null && photo.isNotEmpty
            ? Image.network(photo, fit: BoxFit.cover)
            : Center(
                child: Text(
                  initialsFor(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Iniciales a partir de un nombre ("Carlos López" -> "CL").
String initialsFor(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'R';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts[1][0]).toUpperCase();
}
