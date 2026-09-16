import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_providers.dart';
import '../controllers/recovery_controller.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_panel.dart';
import '../widgets/glass_input_field.dart';
import '../widgets/otp_code_input.dart';
import '../widgets/password_strength.dart';
import '../widgets/primary_button.dart';
import '../widgets/brand_mark.dart';

/// Recuperacion de acceso como UNA experiencia que evoluciona: email -> codigo
/// -> nueva contrasena -> exito. Un solo route (/recover), misma pagina.
class RecoverAccessPage extends ConsumerStatefulWidget {
  const RecoverAccessPage({super.key});

  @override
  ConsumerState<RecoverAccessPage> createState() => _RecoverAccessPageState();
}

class _RecoverAccessPageState extends ConsumerState<RecoverAccessPage> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  PasswordStrength _newPasswordStrength = PasswordStrength.none;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    ref.read(authControllerProvider.notifier).setRecovering(true);
    _newPasswordController.addListener(_onNewPasswordChanged);
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    _newPasswordController.removeListener(_onNewPasswordChanged);
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    ref.read(authControllerProvider.notifier).setRecovering(false);
    super.dispose();
  }

  void _onNewPasswordChanged() {
    final strength =
        getPasswordStrength(_newPasswordController.text);
    if (strength != _newPasswordStrength) {
      setState(() => _newPasswordStrength = strength);
    }
  }

  void _goToLogin() {
    _successTimer?.cancel();
    if (mounted) context.go('/login');
  }

  void _sendCode() {
    ref.read(recoveryControllerProvider.notifier).requestCode(
          _emailController.text,
        );
  }

  void _changePassword() {
    final notifier = ref.read(recoveryControllerProvider.notifier);
    if (_newPasswordController.text.length < 8) return;
    notifier.changePassword(_newPasswordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recoveryControllerProvider);

    ref.listen<RecoveryState>(recoveryControllerProvider, (prev, next) {
      if (next.step == RecoveryStep.success &&
          prev?.step != RecoveryStep.success) {
        _successTimer = Timer(const Duration(milliseconds: 1800), _goToLogin);
      }
      // Al volver al paso email, recuperamos el correo ya ingresado.
      if (next.step == RecoveryStep.email &&
          prev?.step != RecoveryStep.email &&
          _emailController.text.isEmpty &&
          next.email != null) {
        _emailController.text = next.email!;
      }
    });

    return Scaffold(
      body: GlassBackground(
        animatedAurora: false,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 36,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.04),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(state.step),
                        child: _buildStep(state),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: _BackButton(
                  emailStep: state.step == RecoveryStep.email,
                  onTap: () {
                    if (state.step == RecoveryStep.email) {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/login');
                      }
                    } else {
                      ref
                          .read(recoveryControllerProvider.notifier)
                          .back();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Pasos
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep(RecoveryState state) {
    switch (state.step) {
      case RecoveryStep.email:
        return _buildEmailStep(state);
      case RecoveryStep.otp:
        return _buildOtpStep(state);
      case RecoveryStep.password:
        return _buildPasswordStep(state);
      case RecoveryStep.success:
        return _buildSuccessStep();
    }
  }

  Widget _buildBrandHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BrandMark(size: 26),
        SizedBox(width: 9),
        Text(
          'RIVALFIT',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep(RecoveryState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandHeader(),
        const SizedBox(height: 20),
        const Text(
          'Recupera tu acceso',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa el correo asociado a tu cuenta y te enviaremos un código para continuar.',
          style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 14,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GlassInputField(
          controller: _emailController,
          label: 'Correo electrónico',
          hint: 'tu@email.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.mail_outline,
          maxLength: 50,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingresa tu correo';
            }
            final emailRegex = RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            );
            if (!emailRegex.hasMatch(value.trim())) {
              return 'Ingresa un correo válido';
            }
            return null;
          },
          onFieldSubmitted: (_) => _sendCode(),
        ),
        const SizedBox(height: 16),
        if (state.errorMessage != null) ...[
          Text(
            state.errorMessage!,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
        PrimaryButton(
          text: 'Continuar',
          isLoading: state.isSubmitting,
          onPressed: state.isSubmitting ? null : _sendCode,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              _successTimer?.cancel();
              context.go('/login');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textGray,
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('Volver a Iniciar sesión'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(RecoveryState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandHeader(),
        const SizedBox(height: 20),
        const Text(
          'Revisa tu correo',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 14,
              height: 1.4,
            ),
            children: [
              const TextSpan(text: 'Enviamos un código de verificación a '),
              TextSpan(
                text: state.maskedEmail,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        OtpCodeInput(
          isVerifying: state.isSubmitting,
          errorText: state.errorMessage,
          onChanged: (_) => ref
              .read(recoveryControllerProvider.notifier)
              .clearError(),
          onCompleted: (code) => ref
              .read(recoveryControllerProvider.notifier)
              .verifyCode(code),
        ),
        const SizedBox(height: 12),
        if (state.isSubmitting)
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(1)),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: Colors.transparent,
            ),
          )
        else
          const SizedBox(height: 2),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            state.errorMessage!,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿No recibiste el código? ',
              style: TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
            if (state.cooldownSeconds > 0)
              Text(
                'Reenviar en 0:${state.cooldownSeconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 13,
                ),
              )
            else
              TextButton(
                onPressed: state.isSubmitting
                    ? null
                    : () => ref
                        .read(recoveryControllerProvider.notifier)
                        .resendCode(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Reenviar código'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordStep(RecoveryState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandHeader(),
        const SizedBox(height: 20),
        const Text(
          'Crea una nueva contraseña',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Establece una nueva contraseña para volver a entrar a RivalFit.',
          style: TextStyle(
            color: AppColors.textGray,
            fontSize: 14,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GlassInputField(
          controller: _newPasswordController,
          label: 'Nueva contraseña',
          hint: 'Nueva contraseña',
          obscureText: _obscureNew,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.lock_outline,
          maxLength: 25,
          onChanged: (_) =>
              ref.read(recoveryControllerProvider.notifier).clearError(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_newPasswordController.text.isNotEmpty) ...[
                PasswordStrengthIndicator(strength: _newPasswordStrength),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
            ],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa una contraseña';
            }
            if (value.length < 8) {
              return 'Mínimo 8 caracteres';
            }
            return null;
          },
        ),
        if (_newPasswordController.text.isNotEmpty &&
            _newPasswordStrength != PasswordStrength.strong) ...[
          const SizedBox(height: 6),
          PasswordHintsList(password: _newPasswordController.text),
        ],
        const SizedBox(height: 16),
        GlassInputField(
          controller: _confirmController,
          label: 'Confirmar contraseña',
          hint: 'Confirmar contraseña',
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.lock_outline,
          maxLength: 25,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Confirma tu contraseña';
            }
            if (value != _newPasswordController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        if (state.errorMessage != null) ...[
          Text(
            state.errorMessage!,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
        PrimaryButton(
          text: 'Cambiar contraseña',
          isLoading: state.isSubmitting,
          onPressed:
              state.isSubmitting || _newPasswordController.text.length < 8
                  ? null
                  : _changePassword,
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBrandHeader(),
        const SizedBox(height: 28),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.black,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Contraseña actualizada',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Ahora puedes iniciar sesión con tu nueva contraseña.',
          style: TextStyle(color: AppColors.textGray, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Ir a Iniciar sesión',
          onPressed: _goToLogin,
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  final bool emailStep;
  final VoidCallback onTap;

  const _BackButton({required this.emailStep, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          emailStep ? Icons.arrow_back : Icons.arrow_back,
          size: 20,
          color: AppColors.textWhite,
        ),
        tooltip: emailStep ? 'Volver al inicio de sesión' : 'Volver',
        onPressed: onTap,
      ),
    );
  }
}