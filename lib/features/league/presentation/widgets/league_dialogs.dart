import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Lista de emojis que dan identidad de marca a la liga.
const _leagueEmojis = <String>[
  '🏆', '💪', '🔥', '⚡',
  '🎯', '🦁', '🐺', '🚀',
  '👑', '🥇', '⚔️', '🛡️',
  '🐉', '😈', '🧗', '🤺',
];

/// Permite crear una liga eligiendo su identidad (emoji + nombre).
/// [onCreate] debe devolver `null` si la creacion fue exitosa o un mensaje de
/// error; el sheet se cierra solo cuando la liga quedo creada.
Future<void> showCreateLeagueSheet(
  BuildContext context, {
  String initialName = '',
  String initialEmoji = '🏆',
  required Future<String?> Function(String name, String emoji) onCreate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => CreateLeagueSheet(
      initialName: initialName,
      initialEmoji: initialEmoji,
      onCreate: onCreate,
    ),
  );
}

/// Permite unirse a una liga ingresando su codigo de 6 digitos. [onSubmit]
/// debe devolver `null` si el join fue exitoso o un mensaje de error.
Future<void> showJoinLeagueDialog(
  BuildContext context, {
  required Future<String?> Function(String code) onSubmit,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => JoinLeagueDialog(onSubmit: onSubmit),
  );
}

/// Bottom sheet grande para crear la liga: identidad (emoji), nombre,
/// beneficios y CTA tipo Volt. El usuario no sale del contexto de la tab.
class CreateLeagueSheet extends StatefulWidget {
  final String initialName;
  final String initialEmoji;
  final Future<String?> Function(String name, String emoji) onCreate;

  const CreateLeagueSheet({
    super.key,
    this.initialName = '',
    this.initialEmoji = '🏆',
    required this.onCreate,
  });

  @override
  State<CreateLeagueSheet> createState() => _CreateLeagueSheetState();
}

class _CreateLeagueSheetState extends State<CreateLeagueSheet> {
  late final TextEditingController _controller;
  late String _emoji;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _emoji = widget.initialEmoji;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (_creating) return;
    if (name.isEmpty) {
      setState(() => _error = 'Escribe un nombre para tu liga');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    final error = await widget.onCreate(name, _emoji);
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
    return Container(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 12,
        bottom: 16 + insets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
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
                    color: AppColors.subtleBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.volt.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.workspaces_outline,
                      size: 26,
                      color: AppColors.carbon,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crea tu liga',
                          style: TextStyle(
                            color: AppColors.carbon,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Dale identidad y compite contra hasta 10 amigos.',
                          style: TextStyle(
                            color: AppColors.grayMain.withValues(alpha: 0.9),
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
              const SizedBox(height: 22),
              const Text(
                'ÍCONO',
                style: TextStyle(
                  color: AppColors.carbon,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final emoji in _leagueEmojis)
                    GestureDetector(
                      onTap: () => setState(() => _emoji = emoji),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _emoji == emoji
                              ? AppColors.volt
                              : AppColors.panelSoft,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _emoji == emoji
                                ? AppColors.carbon
                                : AppColors.subtleBorder,
                            width: _emoji == emoji ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _controller,
                enabled: !_creating,
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  color: AppColors.carbon,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  labelText: 'Nombre de la liga',
                  labelStyle: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  hintText: 'ej. Club de los Fieras',
                  hintStyle: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.panelSoft,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
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
              const SizedBox(height: 8),
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
              SizedBox(height: _error == null ? 18 : 0),
              const _BenefitsRow(),
              const SizedBox(height: 22),
              Material(
                color: _creating ? AppColors.subtleBorder : AppColors.volt,
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
                                  color: AppColors.carbon,
                                ),
                              ),
                            ]
                          : const [
                              Icon(
                                Icons.workspaces_filled,
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

/// Ristra de beneficios que comunica de un vistazo qué obtienes.
class _BenefitsRow extends StatelessWidget {
  const _BenefitsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BenefitChip(
          icon: Icons.tag_rounded,
          label: 'Código\nautomático',
        ),
        const SizedBox(width: 8),
        _BenefitChip(
          icon: Icons.group_rounded,
          label: 'Hasta\n10 amigos',
        ),
        const SizedBox(width: 8),
        _BenefitChip(
          icon: Icons.sports_gymnastics_rounded,
          label: 'Ranking\nsemanal',
        ),
      ],
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.panelSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.subtleBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.carbon),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.carbon,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
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