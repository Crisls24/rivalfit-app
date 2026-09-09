import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_panel.dart';
import '../widgets/glass_input_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/auth_divider.dart';
import '../widgets/social_login_cards.dart';

enum _UsernameStatus { none, checking, available }

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
  bool _acceptedTerms = false;
  _UsernameStatus _usernameStatus = _UsernameStatus.none;
  bool _submitting = false;
  // Cached strength for password field to avoid recalculating on every build
  _PasswordStrength _passwordStrength = _PasswordStrength.none;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Only listen to password controller to update strength dots — avoids full
    // form rebuild on every keystroke (which caused keyboard lag)
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final newStrength = _getPasswordStrength(_passwordController.text);
    if (newStrength != _passwordStrength) {
      setState(() {
        _passwordStrength = newStrength;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounceTimer?.cancel();
    final trimmed = value.trim();

    // Solo verificamos si cumple con el criterio de longitud y caracteres
    if (trimmed.length < 3 ||
        trimmed.length > 15 ||
        !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(trimmed)) {
      if (_usernameStatus != _UsernameStatus.none) {
        setState(() {
          _usernameStatus = _UsernameStatus.none;
        });
      }
      return;
    }

    setState(() {
      _usernameStatus = _UsernameStatus.checking;
    });

    _debounceTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_nameController.text.trim() == trimmed) {
        setState(() {
          _usernameStatus = _UsernameStatus.available;
        });
      }
    });
  }

  Widget? _buildUsernameSuffix() {
    switch (_usernameStatus) {
      case _UsernameStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(14.0),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        );
      case _UsernameStatus.available:
        return const Icon(
          Icons.check_circle_outline,
          color: AppColors.strengthStrong,
          size: 20,
        );
      case _UsernameStatus.none:
        return null;
    }
  }

  void _handleSignUp() {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) return;
    FocusScope.of(context).unfocus();

    setState(() => _submitting = true);
    ref.read(authControllerProvider.notifier).signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
  }

  _PasswordStrength _getPasswordStrength(String password) {
    if (password.isEmpty) return _PasswordStrength.none;
    int score = 0;
    if (password.length >= 8) score++;
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
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (_submitting) setState(() => _submitting = false);
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
        animatedAurora: true,
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
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.email_outlined,
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

                      // Username field
                      GlassInputField(
                        controller: _nameController,
                        label: 'Nombre de Usuario',
                        hint: 'tunombre',
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.person_outline,
                        suffixIcon: _buildUsernameSuffix(),
                        maxLength: 15,
                        onChanged: _onUsernameChanged,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu nombre de usuario';
                          }
                          final trimmed = value.trim();
                          if (trimmed.length < 3 || trimmed.length > 15) {
                            return 'Debe tener entre 3 y 15 caracteres';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(trimmed)) {
                            return 'Solo letras y números, sin espacios';
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
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.lock_outline,
                        maxLength: 25,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_passwordController.text.isNotEmpty) ...[
                              _PasswordStrengthIndicator(
                                strength: _passwordStrength,
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
                          if (value.length < 8) {
                            return 'Mínimo 8 caracteres';
                          }
                          return null;
                        },
                      ),
                      // Password hints
                      if (_passwordController.text.isNotEmpty &&
                          _passwordStrength != _PasswordStrength.strong)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _PasswordHints(
                            password: _passwordController.text,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Checkbox Términos y Condiciones
                      Row(
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              unselectedWidgetColor: AppColors.textGray,
                            ),
                            child: Checkbox(
                              value: _acceptedTerms,
                              onChanged: (val) {
                                setState(() {
                                  _acceptedTerms = val ?? false;
                                });
                              },
                              activeColor: AppColors.primary,
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: const BorderSide(
                                color: AppColors.textGray,
                                width: 1.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _acceptedTerms = !_acceptedTerms;
                                });
                              },
                              child: const Text(
                                'Acepto los Términos y Condiciones',
                                style: TextStyle(
                                  color: AppColors.textGray,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Sign up button
                      GradientButton(
                        text: 'Crear Cuenta',
                        isLoading: _submitting,
                        onPressed:
                            _acceptedTerms && !_submitting ? _handleSignUp : null,
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
                          // TODO: Apple sign up
                        },
                        onFacebookTap: () => ref
                            .read(authControllerProvider.notifier)
                            .signInWithFacebook(),
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
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppColors.primary,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Inicia Sesión'),
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
    // Dots are cumulative: weak=1 red, medium=2 orange + 1, strong=all 4 green
    final isStrong = strength == _PasswordStrength.strong;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(
          active: strength != _PasswordStrength.none,
          color: isStrong ? AppColors.strengthStrong : AppColors.strengthWeak,
        ),
        const SizedBox(width: 3),
        _Dot(
          active: strength == _PasswordStrength.medium || isStrong,
          color: isStrong ? AppColors.strengthStrong : AppColors.strengthMedium,
        ),
        const SizedBox(width: 3),
        _Dot(
          active: strength == _PasswordStrength.medium || isStrong,
          color: isStrong ? AppColors.strengthStrong : AppColors.strengthMedium,
        ),
        const SizedBox(width: 3),
        _Dot(
          active: isStrong,
          color: AppColors.strengthStrong,
        ),
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
        return 'Débil';
      case _PasswordStrength.medium:
        return 'Media';
      case _PasswordStrength.strong:
        return 'Fuerte';
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

/// Muestra los requisitos que le faltan a la contraseña en tiempo real.
class _PasswordHints extends StatelessWidget {
  final String password;

  const _PasswordHints({required this.password});

  @override
  Widget build(BuildContext context) {
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    final hasLen = password.length >= 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HintRow(met: hasLen, text: 'Mínimo 8 caracteres'),
        _HintRow(met: hasUpper, text: 'Al menos una mayúscula (A-Z)'),
        _HintRow(met: hasNumber, text: 'Al menos un número (0-9)'),
        _HintRow(met: hasSpecial, text: 'Un símbolo (!@#\$%...)'),
      ],
    );
  }
}

class _HintRow extends StatelessWidget {
  final bool met;
  final String text;

  const _HintRow({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 12,
            color: met ? AppColors.strengthStrong : AppColors.textGray,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: met ? AppColors.strengthStrong : AppColors.textGray,
              fontWeight: met ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
