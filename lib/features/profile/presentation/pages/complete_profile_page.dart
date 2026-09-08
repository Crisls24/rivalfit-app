import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/auth/domain/entities/user.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';
import '../widgets/avatar_selector.dart';
import '../widgets/level_card.dart';
import '../widgets/metric_slider.dart';
import '../widgets/volt_button.dart';

/// Onboarding de perfil en 3 pasos ("Forja tu perfil"):
///   1) Alias  2) Rango  3) Métricas base.
/// Indicador ROUND 01/03 con hilo de progreso y vista previa de rival en vivo.
class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _nameFocused = false;

  int _step = 1;
  FitnessLevel? _fitnessLevel;
  double _weightKg = 70;
  int _heightCm = 170;

  Uint8List? _avatarBytes;
  String? _avatarUrl;
  bool _uploadingAvatar = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        ref.read(authControllerProvider).user?.displayName ?? '';
    _nameFocusNode.addListener(_onNameFocusChange);
  }

  void _onNameFocusChange() {
    final focused = _nameFocusNode.hasFocus;
    if (focused != _nameFocused) setState(() => _nameFocused = focused);
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onNameFocusChange);
    _nameFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _fetching {
    final state = ref.read(authControllerProvider);
    return (state.status == AuthStatus.initial ||
            state.status == AuthStatus.loading) &&
        state.user == null;
  }

  bool get _hasName => _nameController.text.trim().isNotEmpty;

  String get _alias {
    final name = _nameController.text.trim().toLowerCase();
    return name.replaceAll(RegExp(r'\s+'), '');
  }

  Color get _accent {
    return switch (_fitnessLevel) {
      FitnessLevel.beginner => AppColors.volt,
      FitnessLevel.intermediate => AppColors.intermediateOrange,
      FitnessLevel.advanced => AppColors.advancedCoral,
      null => AppColors.volt,
    };
  }

  Color get _onAccent => _accent == AppColors.volt ? Colors.black : Colors.white;

  String get _initials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return 'R';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'R';
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }

  void _goTo(int step) => setState(() => _step = step);

  Future<void> _handleSkip() async {
    await ref.read(authControllerProvider.notifier).skipProfile();
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _pickAvatar() async {
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
      _avatarBytes = bytes;
      _uploadingAvatar = true;
    });

    final url = await ref
        .read(authControllerProvider.notifier)
        .uploadAvatar(bytes: bytes, fileName: file.name);

    if (!mounted) return;
    setState(() {
      _uploadingAvatar = false;
      if (url != null) _avatarUrl = url;
    });

    if (url != null) {
      _showSnack('Foto de perfil actualizada', bg: AppColors.success);
    } else {
      _showSnack('Se mostrara solo en este dispositivo por ahora');
    }
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    setState(() => _saving = true);
    final notifier = ref.read(authControllerProvider.notifier);
    await notifier.completeProfile(
      displayName: _nameController.text.trim(),
      fitnessLevel: _fitnessLevel!,
      weightKg: _weightKg,
      heightCm: _heightCm,
      avatarUrl: _avatarUrl,
    );
    if (!mounted) return;

    final state = ref.read(authControllerProvider);
    setState(() => _saving = false);

    if (state.status == AuthStatus.authenticated &&
        state.user?.isProfileComplete == true) {
      _showSnack('Perfil completado. Bienvenido a RivalFit!',
          bg: AppColors.success);
      context.go('/home');
    } else {
      _showSnack(state.errorMessage ?? 'Error al guardar el perfil',
          bg: AppColors.danger);
      notifier.clearError();
    }
  }

  void _showSnack(String message, {Color bg = AppColors.carbon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      body: _fetching
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.volt),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                _arenaBackdrop(),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopRow(),
                        const SizedBox(height: 16),
                        _RoundProgress(step: _step, accent: _accent),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                            child: child,
                          ),
                          child: KeyedSubtree(
                            key: ValueKey('h$_step'),
                            child: _buildStepHeader(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              final curved = CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              );
                              return FadeTransition(
                                opacity: curved,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.05, 0.04),
                                    end: Offset.zero,
                                  ).animate(curved),
                                  child: child,
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey(_step),
                              child: _buildStep(authUser),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCta(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Fondo tipo arena: gradiente luminoso, banda volt diagonal tenue y el
  /// número de paso en "ghost" para llenar sin recargar.
  Widget _arenaBackdrop() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFF1F2F5)],
            ),
          ),
        ),
        Positioned(
          top: -70,
          right: -60,
          child: Transform.rotate(
            angle: 0.6,
            child: Container(
              width: 260,
              height: 190,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.volt.withValues(alpha: 0.14),
                    AppColors.volt.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: 4,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '0$_step',
              key: ValueKey(_step),
              style: TextStyle(
                color: AppColors.carbon.withValues(alpha: 0.045),
                fontSize: 150,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -6,
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 6,
          child: Text(
            'RIVALFIT · FORJA TU PERFIL',
            style: TextStyle(
              color: AppColors.grayMain.withValues(alpha: 0.35),
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.volt,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.volt.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.bolt, color: Colors.black, size: 22),
        ),
        const SizedBox(width: 10),
        const Text(
          'RIVALFIT',
          style: TextStyle(
            color: AppColors.carbon,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.subtleBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextButton(
            onPressed: _handleSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.grayMain,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Omitir',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Step header ─────────────────────────

  Widget _buildStepHeader() {
    return switch (_step) {
      1 => _header(
          'Tu alias de combate',
          'Así te verán en la Liga y en el ranking. Hazlo sonar.'),
      2 => _header(
          'Define tu rango',
          'El ranking ajustará tu reto. Elige tu punto de partida.'),
      _ => _header(
          'Tus métricas base',
          'Las usamos para cálculos y rankings. Podrás ajustarlas después.'),
    };
  }

  Widget _header(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.carbon,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _RoundPill(step: _step),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.grayMain.withValues(alpha: 0.92),
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Steps ─────────────────────────

  Widget _buildStep(User? authUser) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: switch (_step) {
          1 => [..._buildIdentityStep()],
          2 => [..._buildLevelStep()],
          _ => [..._buildPhysicalStep()],
        },
      ),
    );
  }

  List<Widget> _buildIdentityStep() {
    return [
      _fade('i', Center(
        child: AvatarSelector(
          image: _avatarProvider(),
          initials: _initials,
          uploading: _uploadingAvatar,
          onTap: _pickAvatar,
          radius: 44,
        ),
      ), delay: 0),
      const SizedBox(height: 22),
      _fade('n', _buildNameField(), delay: 90),
      const SizedBox(height: 14),
      _fade('r', _buildRivalCard(), delay: 180),
    ];
  }

  Widget _buildNameField() {
    final len = _nameController.text.length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _nameFocused ? AppColors.volt : AppColors.subtleBorder,
          width: _nameFocused ? 2 : 1,
        ),
        boxShadow: _nameFocused
            ? [
                BoxShadow(
                  color: AppColors.volt.withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            textInputAction: TextInputAction.done,
            maxLength: 50,
            onChanged: (_) => setState(() {}),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            style: const TextStyle(
              color: AppColors.carbon,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
            cursorColor: AppColors.volt,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Tu alias',
              hintStyle: TextStyle(
                color: AppColors.carbon.withValues(alpha: 0.22),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
              prefixText: '@ ',
              prefixStyle: TextStyle(
                color: AppColors.carbon.withValues(alpha: 0.35),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
              contentPadding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  size: 12,
                  color: AppColors.grayMain.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 5),
                Text(
                  _hasName ? 'Se mostrará como @$_alias' : 'Así te conocerá tu Liga',
                  style: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.85),
                    fontSize: 10.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '$len/50',
                  style: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.85),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRivalCard() {
    final hasName = _hasName;
    final hasLevel = _fitnessLevel != null;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, size: 13, color: AppColors.carbon),
                const SizedBox(width: 6),
                Text(
                  'VISTA PREVIA DEL RIVAL',
                  style: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.9),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.volt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'EN VIVO',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.avatarBackground,
                    border: Border.all(color: AppColors.carbon, width: 1.2),
                  ),
                  child: _rivalPreviewImage(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              hasName ? '@$_alias' : '@¿quién serás?',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasName
                                    ? AppColors.carbon
                                    : AppColors.grayMain.withValues(alpha: 0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasLevel
                            ? 'Nivel ${_fitnessLevel!.label}'
                            : 'Nivel: sin definir',
                        style: TextStyle(
                          color: hasLevel
                              ? _accent
                              : AppColors.grayMain.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rivalPreviewImage() {
    final image = _avatarProvider();
    if (image == null) {
      return Center(
        child: Text(
          _initials,
          style: const TextStyle(
            color: AppColors.carbon,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }
    return Image(
      image: image,
      fit: BoxFit.cover,
      width: 48,
      height: 48,
    );
  }

  List<Widget> _buildLevelStep() {
    return [
      for (var i = 0; i < FitnessLevel.values.length; i++) ...[
        _fade(
          'l$i',
          LevelCard(
            level: FitnessLevel.values[i],
            selected: _fitnessLevel == FitnessLevel.values[i],
            dimmed: _fitnessLevel != null &&
                _fitnessLevel != FitnessLevel.values[i],
            onTap: () =>
                setState(() => _fitnessLevel = FitnessLevel.values[i]),
          ),
          delay: 120 + i * 80,
        ),
        if (i < FitnessLevel.values.length - 1) const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> _buildPhysicalStep() {
    return [
      _fade('w', _buildStatTile(
        MetricSlider(
          label: 'Peso',
          unit: 'kg',
          min: 40,
          max: 160,
          step: 0.5,
          value: _weightKg,
          accent: _accent,
          onChanged: (v) => setState(() => _weightKg = v),
        ),
      ), delay: 120),
      const SizedBox(height: 14),
      _fade('h', _buildStatTile(
        MetricSlider(
          label: 'Altura',
          unit: 'cm',
          min: 120,
          max: 220,
          step: 1,
          value: _heightCm.toDouble(),
          accent: _accent,
          onChanged: (v) => setState(() => _heightCm = v.round()),
        ),
      ), delay: 200),
      const SizedBox(height: 18),
      _fade('c', _buildReadyCard(), delay: 280),
    ];
  }

  Widget _buildStatTile(Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: child,
    );
  }

  Widget _buildReadyCard() {
    final level = _fitnessLevel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.carbon,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.volt,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿DISPUESTO A DOMINAR?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  level != null
                      ? '@$_alias · ${level.label}'
                      : '@$_alias',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.bolt, color: AppColors.volt, size: 26),
        ],
      ),
    );
  }

  // ───────────────────────── CTA ─────────────────────────

  Widget _buildCta() {
    if (_step == 1) {
      return VoltButton(
        text: 'Continuar',
        backgroundColor: AppColors.carbon,
        textColor: Colors.white,
        icon: Icons.arrow_forward,
        onPressed: _hasName ? () => _goTo(2) : null,
      );
    }
    if (_step == 2) {
      return VoltButton(
        text: 'Encontré mi ritmo',
        backgroundColor: _accent,
        textColor: _onAccent,
        icon: Icons.arrow_forward,
        glowColor: _accent,
        onPressed: _fitnessLevel != null ? () => _goTo(3) : null,
      );
    }
    return VoltButton(
      text: 'Entrar a la Liga',
      backgroundColor: _accent,
      textColor: _onAccent,
      icon: Icons.arrow_forward,
      glowColor: _accent,
      isLoading: _saving,
      onPressed: _handleSave,
    );
  }

  ImageProvider? _avatarProvider() {
    if (_avatarBytes != null) return MemoryImage(_avatarBytes!);
    final photo = ref.read(authControllerProvider).user?.photoUrl;
    if (photo != null) return NetworkImage(photo);
    return null;
  }

  // ───────────────────────── Helpers ─────────────────────────

  Widget _fade(String key, Widget child, {required int delay}) {
    return child.animate(
      key: ValueKey(key),
      delay: Duration(milliseconds: delay),
    ).fadeIn(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    ).slideY(
      begin: 0.06,
      end: 0,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Hilo de progreso (3 segmentos) y pill ROUND
// ─────────────────────────────────────────────────────────────

class _RoundProgress extends StatelessWidget {
  final int step;
  final Color accent;

  const _RoundProgress({required this.step, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              height: 5,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: i + 1 < step
                    ? AppColors.carbon
                    : i + 1 == step
                        ? accent
                        : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(3),
                boxShadow: i + 1 == step
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoundPill extends StatelessWidget {
  final int step;

  const _RoundPill({required this.step});

  @override
  Widget build(BuildContext context) {
    final isFinal = step == 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.volt,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.volt.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        isFinal ? 'FINAL ROUND' : 'ROUND ${step.toString().padLeft(2, '0')}/03',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}