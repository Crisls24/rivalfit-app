import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_emblem_icon.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_keyboard_inset.dart';
import 'package:share_plus/share_plus.dart';

Future<bool?> showCreateLeagueSheet(
  BuildContext context, {
  String initialEmoji = '🏆',
  required Future<String?> Function(
    String name,
    String emoji,
    String? socialBet,
    Uint8List? photoBytes,
    String? photoFileName,
  )
  onCreate,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        CreateLeagueSheet(initialEmoji: initialEmoji, onCreate: onCreate),
  );
}

Future<String?> showLeagueCodeSheet(
  BuildContext context, {
  String initialCode = '',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LeagueCodeSheet(initialCode: initialCode),
  );
}

const _downloadLink = 'https://rivalfit.iscx.site/#descargar';

Future<void> showShareRivalFitSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _LeagueSheet(
      title: 'Compartir RivalFit',
      content: [
        const Center(
          child: LeagueBadge(size: 58, background: AppColors.carbon),
        ),
        const SizedBox(height: 12),
        const Text(
          'Envía el enlace de descarga a tus amigos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grayMain),
        ),
      ],
      actions: [
        FilledButton.icon(
          onPressed: () async {
            final box = sheetContext.findRenderObject() as RenderBox?;
            final origin = box == null || !box.hasSize
                ? null
                : box.localToGlobal(Offset.zero) & box.size;
            try {
              await SharePlus.instance.share(
                ShareParams(
                  text:
                      'Descarga RivalFit para entrenar y competir con tus amigos.\n\n$_downloadLink',
                  sharePositionOrigin: origin,
                ),
              );
            } catch (_) {
              if (!sheetContext.mounted) return;
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No pudimos abrir las opciones para compartir.',
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.share_outlined, size: 18),
          label: const Text('Compartir enlace'),
          style: _voltButton,
        ),
        const SizedBox(height: 6),
        FilledButton.tonalIcon(
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: _downloadLink));
            if (!sheetContext.mounted) return;
            Navigator.of(sheetContext).pop();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Enlace copiado')));
          },
          icon: const Icon(Icons.content_copy_rounded, size: 18),
          label: const Text('Copiar enlace'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.panelSoft,
            foregroundColor: AppColors.carbon,
            minimumSize: const Size(0, 48),
          ),
        ),
      ],
    ),
  );
}

final _voltButton = FilledButton.styleFrom(
  backgroundColor: AppColors.volt,
  foregroundColor: AppColors.carbon,
  disabledBackgroundColor: AppColors.panelSoft,
  disabledForegroundColor: AppColors.grayMain,
  minimumSize: const Size(0, 48),
);

InputDecoration _leagueField(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.grayMain),
  filled: true,
  fillColor: AppColors.panelSoft,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.volt, width: 2),
  ),
);

class _LeagueSheet extends StatelessWidget {
  const _LeagueSheet({
    required this.title,
    required this.content,
    required this.actions,
    this.busy = false,
  });

  final String title;
  final List<Widget> content;
  final List<Widget> actions;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !busy,
      child: LeagueKeyboardInset(
        child: Material(
          color: AppColors.iceBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: AppColors.carbon,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: busy
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              tooltip: 'Cerrar',
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.carbon,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...content,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateLeagueSheet extends StatefulWidget {
  final String initialEmoji;
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
    this.initialEmoji = '🏆',
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
  bool _showChallenge = false;
  String? _nameError;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _betController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _betController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
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
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos abrir la foto.');
    }
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    final socialBet = _betController.text.trim();
    if (_creating) return;
    if (name.length < 3) {
      setState(() => _nameError = 'Escribe al menos 3 caracteres');
      return;
    }
    FocusScope.of(context).unfocus();
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
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _creating = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _LeagueSheet(
      title: 'Crear liga',
      busy: _creating,
      content: [
        const Text(
          'Nombre de la liga',
          style: TextStyle(
            color: AppColors.carbon,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          enabled: !_creating,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          style: const TextStyle(color: AppColors.carbon),
          decoration: _leagueField('Los del lunes')
              .copyWith(errorText: _nameError),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _creating ? null : _pickPhoto,
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    LeagueBadge(
                      bytes: _photoBytes,
                      size: 54,
                      background: AppColors.carbon,
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.edit_outlined,
                      size: 17,
                      color: AppColors.carbon,
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Cambiar foto',
                        style: TextStyle(
                          color: AppColors.carbon,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_photoBytes != null)
              IconButton(
                tooltip: 'Quitar foto',
                onPressed: _creating
                    ? null
                    : () => setState(() {
                        _photoBytes = null;
                        _photoFileName = null;
                      }),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.grayMain,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _creating
              ? null
              : () => setState(() => _showChallenge = !_showChallenge),
          icon: Icon(_showChallenge ? Icons.expand_less : Icons.add_rounded),
          label: Text(
            _showChallenge
                ? 'Ocultar reto'
                : _betController.text.trim().isEmpty
                ? 'Añadir reto opcional'
                : 'Editar reto opcional',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.panelSoft,
            foregroundColor: AppColors.carbon,
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        if (_showChallenge) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _betController,
            enabled: !_creating,
            maxLength: 80,
            style: const TextStyle(color: AppColors.carbon),
            textCapitalization: TextCapitalization.sentences,
            decoration: _leagueField('Ej. El último paga la cena'),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final suggestion in const [
                'El último paga la cena',
                'Quien pierda organiza la revancha',
              ])
                ActionChip(
                  label: Text(suggestion),
                  onPressed: _creating
                      ? null
                      : () => _betController.text = suggestion,
                ),
            ],
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
      ],
      actions: [
        FilledButton(
          onPressed: _creating ? null : _submit,
          style: _voltButton,
          child: Text(_creating ? 'Creando…' : 'Crear liga'),
        ),
      ],
    );
  }
}

class _LeagueCodeSheet extends StatefulWidget {
  const _LeagueCodeSheet({required this.initialCode});

  final String initialCode;

  @override
  State<_LeagueCodeSheet> createState() => _LeagueCodeSheetState();
}

class _LeagueCodeSheetState extends State<_LeagueCodeSheet> {
  late final _controller = TextEditingController(text: widget.initialCode);
  static final _validCode = RegExp(r'^[A-Z0-9]{6}$');
  String? _error;

  String get _code => _controller.text.toUpperCase();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_validCode.hasMatch(_code)) Navigator.of(context).pop(_code);
  }

  Future<void> _paste() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final code = clipboard?.text?.trim().toUpperCase() ?? '';
    if (!_validCode.hasMatch(code)) {
      setState(() => _error = 'Copia un código de 6 letras o números.');
      return;
    }
    _controller.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    _clearError();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return _LeagueSheet(
      title: 'Tengo un código',
      content: [
        const Text(
          'Escribe o pega los 6 caracteres.',
          style: TextStyle(color: AppColors.grayMain),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.go,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (_) => _clearError(),
          onSubmitted: (_) => _submit(),
          style: const TextStyle(
            color: AppColors.carbon,
            fontSize: 19,
            letterSpacing: 3,
          ),
          decoration: _leagueField('ABC123').copyWith(
            errorText: _error,
            semanticCounterText: 'Código de 6 caracteres',
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _paste,
            style: TextButton.styleFrom(foregroundColor: AppColors.carbon),
            icon: const Icon(Icons.content_paste_rounded, size: 17),
            label: const Text('Pegar código'),
          ),
        ),
      ],
      actions: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          child: const Text('Ver liga'),
          builder: (context, value, child) => FilledButton(
            onPressed: _validCode.hasMatch(value.text.toUpperCase())
                ? _submit
                : null,
            style: _voltButton,
            child: child,
          ),
        ),
      ],
    );
  }
}
