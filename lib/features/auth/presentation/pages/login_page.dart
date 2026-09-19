import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

import '../controllers/auth_controller.dart';
import '../controllers/auth_providers.dart';
import '../controllers/recovery_controller.dart';
import '../widgets/auth_divider.dart';
import '../widgets/brand_mark.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_input_field.dart';
import '../widgets/glass_panel.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_login_cards.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Mensaje post-recuperacion: la clave se actualizo y ya puede iniciar.
    ref.listen<RecoveryState>(recoveryControllerProvider, (prev, next) {
      if (next.justCompleted && !(prev?.justCompleted ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Contraseña actualizada. Inicia sesión.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(recoveryControllerProvider.notifier).reset();
      }
    });

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.danger,
          ),
        );
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: GlassBackground(
        animatedAurora: false,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Marca: unidad visual RIVALFIT (cuadrado lima + rayo)
                      const Row(
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
                      ),
                      const SizedBox(height: 20),
                      // Title
                      const Text(
                        '¡Bienvenido!',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        'Nos alegra tenerte aquí otra vez',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Email field
                      GlassInputField(
                        controller: _emailController,
                        label: 'Correo Electrónico',
                        hint: 'Correo Electrónico',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.person_outline,
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
                      ),
                      const SizedBox(height: 16),
                      // Password field
                      GlassInputField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        hint: 'Contraseña',
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        maxLength: 25,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          if (value.length < 8) {
                            return 'Mínimo 8 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ref
                                .read(authControllerProvider.notifier)
                                .setRecovering(true);
                            context.push('/recover');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            foregroundColor: AppColors.textGray,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Login button
                      PrimaryButton(
                        text: 'Iniciar sesión',
                        isLoading: authState.status == AuthStatus.loading,
                        onPressed: authState.status == AuthStatus.loading
                            ? null
                            : _handleLogin,
                      ),
                      const SizedBox(height: 24),
                      // Divider
                      const AuthDivider(text: 'O continua con'),
                      const SizedBox(height: 24),
                      // Social login
                      SocialLoginCards(
                        onGoogleTap: () => ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle(),
                        onAppleTap: () {
                          // TODO: Apple sign in
                        },
                        onFacebookTap: () => ref
                            .read(authControllerProvider.notifier)
                            .signInWithFacebook(),
                      ),
                      const SizedBox(height: 24),
                      // Sign up link
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 13,
                            ),
                            children: [
                              const TextSpan(text: '¿No tienes cuenta? '),
                              TextSpan(
                                text: 'Regístrate',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => context.push('/signup'),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
