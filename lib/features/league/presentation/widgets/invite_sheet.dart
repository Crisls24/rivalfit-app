import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/core/deeplinks/deep_link_parser.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_providers.dart';
import 'package:rivalfit/features/league/presentation/widgets/member_tile.dart';

/// La invitacion se comparte SIEMPRE con el enlace https verificado por App
/// Links (https://fit-api.iscx.site/join/CODE). El custom scheme
/// (com.rivalfit.rivalfit://join/CODE) queda solo como compatibilidad interna
/// y nunca llega a un amigo.

Future<void> showInviteSheet(BuildContext context, League league) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InviteSheet(league: league),
  );
}

class _InviteSheet extends ConsumerStatefulWidget {
  final League league;

  const _InviteSheet({required this.league});

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  final TextEditingController _controller = TextEditingController();
  List<UserSearchResult> _results = const [];
  bool _searching = false;
  String? _searchError;

  String get _link => joinInviteLink(widget.league.code);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enlace copiado')),
    );
  }

  Future<void> _share() async {
    final message = 'Te reto a mi Liga de RIVALFIT 🟢\n'
        '\n'
        'Únete y compitamos esta semana.\n'
        '\n'
        '${widget.league.name}\n'
        '${widget.league.memberCount}/${widget.league.maxMembers} competidores\n'
        '\n'
        '$_link';
    await SharePlus.instance.share(ShareParams(text: message));
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _searchError = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    final result = await ref.read(leagueRepositoryProvider).searchByAlias(q);
    if (!mounted) return;
    setState(() {
      _searching = false;
      if (result.error != null) {
        _searchError = result.error!.message;
        _results = const [];
      } else {
        _results = result.items;
      }
    });
  }

  Future<void> _pickUser(UserSearchResult user) async {
    await Clipboard.setData(ClipboardData(text: _link));
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Enlace copiado para @${user.alias ?? user.displayName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 20 + insets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: StatefulBuilder(builder: (context, setSheetState) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.subtleBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.volt.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          widget.league.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Invitar a mi liga',
                            style: TextStyle(
                              color: AppColors.carbon,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.league.name,
                            style: TextStyle(
                              color: AppColors.grayMain.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _CodePanel(code: widget.league.code, onCopy: _copyLink),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.link_rounded,
                        label: 'Copiar enlace',
                        onTap: _copyLink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share_rounded,
                        label: 'Compartir',
                        volt: true,
                        onTap: _share,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Buscar por @alias',
                  style: TextStyle(
                    color: AppColors.carbon,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.none,
                  autofocus: false,
                  onSubmitted: _search,
                  style: const TextStyle(
                    color: AppColors.carbon,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '@alias',
                    hintStyle: TextStyle(
                      color: AppColors.grayMain.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.grayMain,
                    ),
                    filled: true,
                    fillColor: AppColors.panelSoft,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 13),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.volt),
                    ),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.grayMain,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                if (_searchError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _searchError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (_results.isEmpty && !_searching)
                  Text(
                    'Busca a tu amigo y te compartiremos el enlace de invitación.',
                    style: TextStyle(
                      color: AppColors.grayMain.withValues(alpha: 0.8),
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  ..._results.map(
                    (user) => InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _pickUser(user),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            _MiniAvatar(user: user),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '@${user.alias ?? user.displayName}',
                                    style: const TextStyle(
                                      color: AppColors.carbon,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    user.displayName,
                                    style: TextStyle(
                                      color: AppColors.grayMain
                                          .withValues(alpha: 0.85),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.link_rounded,
                              size: 18,
                              color: AppColors.grayMain,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final UserSearchResult user;

  const _MiniAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final photo = user.photoUrl;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.avatarBackground,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: ClipOval(
        child: photo != null && photo.isNotEmpty
            ? Image.network(photo, fit: BoxFit.cover)
            : Center(
                child: Text(
                  initialsFor(user.displayName),
                  style: const TextStyle(
                    color: AppColors.carbon,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
      ),
    );
  }
}

class _CodePanel extends StatelessWidget {
  final String code;
  final Future<void> Function() onCopy;

  const _CodePanel({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.carbon,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CÓDIGO DE INVITACIÓN',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: const TextStyle(
                    color: AppColors.volt,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.glowNeutral,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool volt;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.volt = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = volt ? AppColors.volt : AppColors.panelSoft;
    final foreground = volt ? AppColors.carbon : AppColors.carbon;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13.5,
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