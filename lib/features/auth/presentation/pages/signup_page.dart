import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autohost/app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_panel.dart';
import '../widgets/glass_input_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/auth_divider.dart';
import '../widgets/social_login_cards.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
  }

  _PasswordStrength _getPasswordStrength(String password) {
    if (password.isEmpty) return _PasswordStrength.none;
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return _PasswordStrength.weak;
    if (score <= 3) return _PasswordStrength.medium;
    return _PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final passwordStrength = _getPasswordStrength(_passwordController.text);

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: colorScheme.error,
          ),
        );
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: GlassBackground(
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
                  onChanged: () => setState(() {}),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      const Text(
                        'Comienza gratis',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      const Text(
                        '100% gratis. No requiere tarjeta',
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
                        hint: 'tunombre@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu correo';
                          }
                          if (!value.contains('@')) {
                            return 'Correo inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Username field
                      GlassInputField(
                        controller: _nameController,
                        label: 'Nombre de Usuario',
                        hint: 'tunombre',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu nombre';
                          }
                          if (value.length < 2) {
                            return 'Mínimo 2 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password field with strength meter
                      GlassInputField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        hint: 'Contraseña',
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_passwordController.text.isNotEmpty) ...[
                              _PasswordStrengthIndicator(
                                strength: passwordStrength,
                              ),
                              const SizedBox(width: 8),
                            ],
                            IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa una contraseña';
                          }
                          if (value.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Sign up button
                      GradientButton(
                        text: 'Sign up',
                        isLoading: authState.status == AuthStatus.loading,
                        onPressed: authState.status == AuthStatus.loading
                            ? null
                            : _handleSignUp,
                      ),
                      const SizedBox(height: 24),
                      // Divider
                      const AuthDivider(text: 'o Regístrate con'),
                      const SizedBox(height: 24),
                      // Social login
                      SocialLoginCards(
                        onGoogleTap: () => ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle(),
                        onAppleTap: () {
                          // TODO: Apple sign in
                        },
                        onFacebookTap: () {
                          // TODO: Facebook sign in
                        },
                      ),
                      const SizedBox(height: 24),
                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tienes cuenta? ',
                            style: TextStyle(
                              color: AppColors.textGray,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: const Text(
                              'Inicia sesión',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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

enum _PasswordStrength { none, weak, medium, strong }

class _PasswordStrengthIndicator extends StatelessWidget {
  final _PasswordStrength strength;

  const _PasswordStrengthIndicator({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(active: strength == _PasswordStrength.weak, color: AppColors.strengthWeak),
        const SizedBox(width: 3),
        _Dot(active: strength == _PasswordStrength.weak || strength == _PasswordStrength.medium, color: AppColors.strengthMedium),
        const SizedBox(width: 3),
        _Dot(active: strength == _PasswordStrength.medium, color: AppColors.strengthMedium),
        const SizedBox(width: 3),
        _Dot(active: strength == _PasswordStrength.strong, color: AppColors.strengthStrong),
        const SizedBox(width: 6),
        Text(
          _getStrengthText(strength),
          style: TextStyle(
            color: _getStrengthColor(strength),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getStrengthText(_PasswordStrength s) {
    switch (s) {
      case _PasswordStrength.none:
        return '';
      case _PasswordStrength.weak:
        return 'Weak';
      case _PasswordStrength.medium:
        return 'Medium';
      case _PasswordStrength.strong:
        return 'Strong';
    }
  }

  Color _getStrengthColor(_PasswordStrength s) {
    switch (s) {
      case _PasswordStrength.none:
        return AppColors.textGray;
      case _PasswordStrength.weak:
        return AppColors.strengthWeak;
      case _PasswordStrength.medium:
        return AppColors.strengthMedium;
      case _PasswordStrength.strong:
        return AppColors.strengthStrong;
    }
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final Color color;

  const _Dot({required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? color : AppColors.textGray.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}
