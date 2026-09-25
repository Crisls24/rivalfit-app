import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/core/deeplinks/deep_link_parser.dart';
import 'package:rivalfit/features/league/domain/invite_message.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_emblem_icon.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showCreateLeagueSheet(
  BuildContext context, {
  String initialName = '',
  String initialEmoji = '🏆',
  String? initialSocialBet,
  required Future<String?> Function(
    String name,
    String emoji,
    String? socialBet,
    Uint8List? photoBytes,
    String? photoFileName,
  )
  onCreate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => CreateLeagueSheet(
      initialName: initialName,
      initialEmoji: initialEmoji,
      initialSocialBet: initialSocialBet,
      onCreate: onCreate,
    ),
  );
}

Future<void> showLeagueCreatedDialog(
  BuildContext context, {
  required League league,
  VoidCallback? onInvite,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) =>
        _LeagueCreatedDialog(league: league, onInvite: onInvite),
  );
}

Future<void> showJoinLeagueDialog(
  BuildContext context, {
  required Future<String?> Function(String code) onSubmit,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => JoinLeagueDialog(onSubmit: onSubmit),
  );
}

class CreateLeagueSheet extends StatefulWidget {
  final String initialName;
  final String initialEmoji;
  final String? initialSocialBet;
  final Future<String?> Function(
    String name,
    String emoji,
    String? socialBet,
    Uint8List? photoBytes,
    String? photoFileName,
  )
  onCreate;

  const CreateLeagueSheet({
    super.key,
    this.initialName = '',
    this.initialEmoji = '🏆',
    this.initialSocialBet,
    required this.onCreate,
  });

  @override
  State<CreateLeagueSheet> createState() => _CreateLeagueSheetState();
}

class _CreateLeagueSheetState extends State<CreateLeagueSheet> {
  late final TextEditingController _controller;
  late final TextEditingController _betController;
  Uint8List? _photoBytes;
  String? _photoFileName;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _betController = TextEditingController(text: widget.initialSocialBet ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _betController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
      _photoFileName = file.name;
    });
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    final socialBet = _betController.text.trim();
    if (_creating) return;
    if (name.length < 3) {
      setState(() => _error = 'Mínimo 3 caracteres');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    final error = await widget.onCreate(
      name,
      widget.initialEmoji,
      socialBet.isEmpty ? null : socialBet,
      _photoBytes,
      _photoFileName,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _creating = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    final previewName = _controller.text.trim();
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 18 + insets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glowNeutral,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  LeagueBadge(bytes: _photoBytes, size: 56, background: AppColors.volt.withValues(alpha: 0.14), borderColor: AppColors.volt.withValues(alpha: 0.44)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crear liga',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Compite con tus amigos cada semana.',
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glowNeutral,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    LeagueBadge(bytes: _photoBytes, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (previewName.isEmpty ? 'NUEVA LIGA' : previewName)
                                .toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '10 CUPOS MÁX',
                            style: TextStyle(
                              color: AppColors.volt,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nombre de la liga',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                enabled: !_creating,
                maxLength: 20,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'Ej. Los Fieras',
                  hintStyle: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.glowNeutral,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.volt),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Foto de la liga',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: AppColors.glowNeutral,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _creating ? null : _pickPhoto,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _photoBytes == null
                              ? Icons.add_a_photo_outlined
                              : Icons.change_history,
                          size: 18,
                          color: _photoBytes == null
                              ? AppColors.volt
                              : Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _photoBytes == null
                                ? 'Elegir foto de tu grupo'
                                : 'Foto elegida · presiona para cambiar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_photoBytes != null)
                          InkWell(
                            onTap: _creating
                                ? null
                                : () => setState(() {
                                      _photoBytes = null;
                                      _photoFileName = null;
                                    }),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.textGray,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sin foto, tu liga usa el emblema de RivalFit.',
                style: TextStyle(
                  color: AppColors.textPlaceholder,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Apuesta opcional',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _betController,
                enabled: !_creating,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Ej. El último paga la cena',
                  hintStyle: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppColors.glowNeutral,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.volt),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'El último paga la cena',
                      'Quien pierda paga el brunch',
                      'La derrota paga la sesión',
                    ].map((text) {
                      final selected = _betController.text.trim() == text;
                      return GestureDetector(
                        onTap: () {
                          if (selected) {
                            _betController.clear();
                          } else {
                            _betController.text = text;
                            _betController.selection = TextSelection.collapsed(
                              offset: _betController.text.length,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.volt
                                : AppColors.glowNeutral,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected
                                  ? AppColors.volt
                                  : AppColors.glassBorder,
                            ),
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: selected ? AppColors.carbon : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 15,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Material(
                color: _creating ? AppColors.glowNeutral : AppColors.volt,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _creating ? null : _submit,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _creating
                          ? const [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.volt,
                                ),
                              ),
                            ]
                          : const [
                              Icon(
                                Icons.handshake_rounded,
                                size: 18,
                                color: AppColors.carbon,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Crear liga',
                                style: TextStyle(
                                  color: AppColors.carbon,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JoinLeagueDialog extends StatefulWidget {
  final Future<String?> Function(String code) onSubmit;

  const JoinLeagueDialog({super.key, required this.onSubmit});

  @override
  State<JoinLeagueDialog> createState() => _JoinLeagueDialogState();
}

class _JoinLeagueDialogState extends State<JoinLeagueDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onSubmit(code);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text(
        'Unirme con código',
        style: TextStyle(
          color: AppColors.carbon,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresa el código de 6 caracteres que te compartió quien creó la liga.',
            style: TextStyle(
              color: AppColors.grayMain.withValues(alpha: 0.85),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_busy,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              color: AppColors.carbon,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              hintText: '8F4K9X',
              counterText: '',
              hintStyle: TextStyle(
                color: AppColors.grayMain.withValues(alpha: 0.7),
                fontSize: 16,
                letterSpacing: 4,
              ),
              filled: true,
              fillColor: AppColors.panelSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.volt),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: AppColors.grayMain,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.volt,
            foregroundColor: AppColors.carbon,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.carbon,
                  ),
                )
              : const Text('Unirme'),
        ),
      ],
    );
  }
}

class _LeagueCreatedDialog extends StatelessWidget {
  final League league;
  final VoidCallback? onInvite;

  const _LeagueCreatedDialog({required this.league, this.onInvite});

  @override
  Widget build(BuildContext context) {
    final link = joinInviteLink(league.code);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.backgroundDark,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LeagueBadge(
                  photoUrl: league.photoUrl,
                  size: 42,
                  background: AppColors.volt.withValues(alpha: 0.18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Liga creada',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.glowNeutral,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1 / 10 miembros',
                    style: TextStyle(
                      color: AppColors.volt,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    league.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDeep,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      league.code,
                      style: const TextStyle(
                        color: AppColors.volt,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SimpleActionButton(
                    label: 'Copiar',
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: league.code));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Código copiado')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SimpleActionButton(
                    label: 'Compartir',
                    onTap: () async {
                      final text = leagueInviteMessage(
                        leagueName: league.name,
                        memberCount: 1,
                        maxMembers: league.maxMembers,
                        link: link,
                      );
                      await SharePlus.instance.share(ShareParams(text: text));
                    },
                    filled: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onInvite != null) {
                    onInvite!();
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.volt,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Invitar por @alias'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _SimpleActionButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? AppColors.volt : AppColors.glowNeutral;
    final fg = filled ? AppColors.carbon : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
