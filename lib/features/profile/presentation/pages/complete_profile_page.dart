import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/features/auth/domain/entities/user.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';

import '../widgets/identity_step.dart';
import '../widgets/metrics_step.dart';
import '../widgets/rank_step.dart';
import '../widgets/step_indicator.dart';
import '../widgets/volt_button.dart';

/// Onboarding de perfil en 3 pasos — "Forja tu perfil".
///
/// Rediseño "Card Flotante Plana":
///   • Fondo arena con textura dot-grid sutil.
///   • StepIndicator numerado (01/02/03) con burbujas animadas.
///   • Header con número de paso en ghosting + título bold.
///   • Cada paso vive en su propio widget (identity / metrics / rank).
///
/// Toda la lógica de estado, subida y navegación se mantiene intacta.
class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  // ─────────────────────── Estado ───────────────────────
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _nameFocused = false;

  final _ageController = TextEditingController();
  final _ageFocusNode = FocusNode();
  bool _ageFocused = false;

  int _step = 1;
  FitnessLevel? _fitnessLevel;
  double _weightKg = 70;
  int _heightCm = 170;

  Uint8List? _avatarBytes;
  String? _avatarUrl;
  bool _uploadingAvatar = false;
  bool _saving = false;

  // ─────────────────────── Init / Dispose ───────────────────────

  @override
  void initState() {
    super.initState();
    _nameController.text =
        ref.read(authControllerProvider).user?.displayName ?? '';
    _nameFocusNode.addListener(_onNameFocusChange);
    _ageFocusNode.addListener(_onAgeFocusChange);
  }

  void _onNameFocusChange() {
    final focused = _nameFocusNode.hasFocus;
    if (focused != _nameFocused) setState(() => _nameFocused = focused);
  }

  void _onAgeFocusChange() {
    final focused = _ageFocusNode.hasFocus;
    if (focused != _ageFocused) setState(() => _ageFocused = focused);
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onNameFocusChange);
    _nameFocusNode.dispose();
    _nameController.dispose();
    _ageFocusNode.removeListener(_onAgeFocusChange);
    _ageFocusNode.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // ─────────────────────── Computed ───────────────────────

  bool get _fetching {
    final state = ref.read(authControllerProvider);
    return (state.status == AuthStatus.initial ||
            state.status == AuthStatus.loading) &&
        state.user == null;
  }

  bool get _hasName => _nameController.text.trim().isNotEmpty;

  int? get _age => int.tryParse(_ageController.text.trim());

  bool get _hasValidAge {
    final age = _age;
    return age != null && age >= 13 && age <= 99;
  }

  String get _alias {
    final name = _nameController.text.trim().toLowerCase();
    return name.replaceAll(RegExp(r'\s+'), '');
  }

  Color get _accent => switch (_fitnessLevel) {
        FitnessLevel.beginner => AppColors.volt,
        FitnessLevel.intermediate => AppColors.intermediateOrange,
        FitnessLevel.advanced => AppColors.advancedCoral,
        null => AppColors.volt,
      };

  String get _initials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return 'R';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'R';
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }

  ImageProvider? _avatarProvider() {
    if (_avatarBytes != null) return MemoryImage(_avatarBytes!);
    final photo = ref.read(authControllerProvider).user?.photoUrl;
    if (photo != null) return NetworkImage(photo);
    return null;
  }

  // ─────────────────────── Acciones ───────────────────────

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
      _showSnack(
        state.errorMessage ?? 'Error al guardar el perfil',
        bg: AppColors.danger,
      );
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

  // ─────────────────────── Build ───────────────────────

  @override
  Widget build(BuildContext context) {
    // watch dispara rebuild cuando el estado de auth cambia
    // (ej. loading → authenticated) para que _fetching se recalcule.
    ref.watch(authControllerProvider);
    return PopScope(
      canPop: _step == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_step > 1) _goTo(_step - 1);
      },
      child: Scaffold(
      backgroundColor: AppColors.iceBackground,
      resizeToAvoidBottomInset: true,
      body: _fetching
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.volt),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                // Fondo limpio con gradiente extremadamente sutil
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, AppColors.iceBackground],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 10),

                        // Stepper numerado (tap para ir al paso)
                        StepIndicator(
                          currentStep: _step,
                          accent: _accent,
                          onStepTap: (step) => _goTo(step),
                        ),
                        SizedBox(height: _step > 1 ? 28 : 16),

                        // Header con número ghost + título
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOut,
                            ),
                            child: child,
                          ),
                          child: KeyedSubtree(
                            key: ValueKey('h$_step'),
                            child: _buildStepHeader(),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Contenido del paso
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, anim) {
                              final curved = CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutCubic,
                              );
                              return FadeTransition(
                                opacity: curved,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.04, 0.03),
                                    end: Offset.zero,
                                  ).animate(curved),
                                  child: child,
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey(_step),
                              child: _buildStepContent(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // CTA
                        _buildCta(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  // ─────────────────────── Header ───────────────────────

  /// Número de paso en ghosting grande (02) + título bold + subtítulo.
  Widget _buildStepHeader() {
    const headers = [
      ('Identidad de combate', 'Elige el alias y el avatar con el que te verán.'),
      ('Tus métricas\nbase', 'Estos datos se requieren para ajustarnos a ti.'),
      ('Define tu rango', 'Elige el nivel que mejor representa tu punto de partida.'),
    ];
    final (title, subtitle) = headers[_step - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.carbon,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.grayMain.withValues(alpha: 0.9),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ─────────────────────── Contenido por paso ───────────────────────

  Widget _buildStepContent() => switch (_step) {
        1 => IdentityStep(
            avatarImage: _avatarProvider(),
            initials: _initials,
            uploading: _uploadingAvatar,
            onPickAvatar: _pickAvatar,
            nameController: _nameController,
            nameFocusNode: _nameFocusNode,
            nameFocused: _nameFocused,
            hasName: _hasName,
            alias: _alias,
            onNameChanged: () => setState(() {}),
            onUnfocus: () => FocusScope.of(context).unfocus(),
            ageController: _ageController,
            ageFocusNode: _ageFocusNode,
            ageFocused: _ageFocused,
            hasAge: _hasValidAge,
            onAgeChanged: () => setState(() {}),
            onAgeUnfocus: () => FocusScope.of(context).unfocus(),
          ),
        2 => MetricsStep(
            weightKg: _weightKg,
            heightCm: _heightCm,
            onWeightChanged: (v) => setState(() => _weightKg = v),
            onHeightChanged: (v) => setState(() => _heightCm = v),
          ),
        _ => RankStep(
            selectedLevel: _fitnessLevel,
            onLevelSelected: (level) => setState(() => _fitnessLevel = level),
          ),
      };

  // ─────────────────────── Top bar ───────────────────────

  Widget _buildTopBar() {
    return Row(
      children: [
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Omitir',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────── CTA ───────────────────────

  Widget _buildCta() {
    if (_step == 1) {
      return VoltButton(
        text: 'Continuar',
        backgroundColor: AppColors.carbon,
        textColor: Colors.white,
        icon: Icons.arrow_forward,
        onPressed: (_hasName && _hasValidAge) ? () => _goTo(2) : null,
      );
    }
    if (_step == 2) {
      return VoltButton(
        text: 'Continuar',
        backgroundColor: AppColors.carbon,
        textColor: Colors.white,
        icon: Icons.arrow_forward,
        onPressed: () => _goTo(3),
      );
    }
    return VoltButton(
      text: 'Entrar a la Liga',
      backgroundColor: AppColors.carbon,
      textColor: Colors.white,
      icon: Icons.arrow_forward,
      iconColor: AppColors.volt,
      isLoading: _saving,
      onPressed: _fitnessLevel != null ? _handleSave : null,
    );
  }
}