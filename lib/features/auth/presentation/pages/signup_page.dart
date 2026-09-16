import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_panel.dart';
import '../widgets/glass_input_field.dart';
import '../widgets/password_strength.dart';
import '../widgets/primary_button.dart';
import '../widgets/auth_divider.dart';
import '../widgets/brand_mark.dart';
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
  bool _acceptedTerms = false;
  bool _usernameValid = false;
  bool _submitting = false;
  String? _emailServerError;
  // Fuerza de la contrasena en cache: evita recalcular y repintar el form en
  // cada tecla, lo que causaba lag del teclado.
  PasswordStrength _passwordStrength = PasswordStrength.none;

  @override
  void initState() {
    super.initState();
    // Escuchamos solo el campo de contrasena para actualizar los puntos de
    // fuerza sin reconstruir todo el formulario en cada caracter.
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final newStrength = getPasswordStrength(_passwordController.text);
    if (newStrength != _passwordStrength) {
      setState(() {
        _passwordStrength = newStrength;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    final trimmed = value.trim();
    final valid = trimmed.length >= 3 &&
        trimmed.length <= 15 &&
        RegExp(r'^[a-zA-Z0-9]+$').hasMatch(trimmed);
    if (valid == _usernameValid) return;
    setState(() {
      _usernameValid = valid;
    });
  }

  Widget? _buildUsernameSuffix() {
    if (!_usernameValid) return null;
    return const Icon(
      Icons.check_circle_outline,
      color: AppColors.strengthStrong,
      size: 20,
    );
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

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (_submitting) setState(() => _submitting = false);
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        final msg = next.errorMessage!;
        // El error "correo ya registrado" se muestra inline bajo el campo.
        if (msg.contains('ya está registrado')) {
          setState(() => _emailServerError = msg);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _formKey.currentState?.validate();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.danger,
            ),
          );
        }
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
                  vertical: 28,
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
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 6),
                      // Subtitle
                      const Text(
                        '100% gratis. No requiere tarjeta',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Email field
                      GlassInputField(
                        controller: _emailController,
                        label: 'Correo Electrónico',
                        hint: 'tunombre@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.email_outlined,
                        maxLength: 50,
                        onChanged: (value) {
                          if (_emailServerError != null) {
                            setState(() => _emailServerError = null);
                          }
                        },
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
                          if (_emailServerError != null) return _emailServerError;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

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
                      const SizedBox(height: 12),

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
                              PasswordStrengthIndicator(
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
                          _passwordStrength != PasswordStrength.strong)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: PasswordHintsList(
                            password: _passwordController.text,
                          ),
                        ),
                      const SizedBox(height: 12),

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
                              checkColor: Colors.black,
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
                      const SizedBox(height: 14),

                      // Sign up button
                      PrimaryButton(
                        text: 'Crear Cuenta',
                        isLoading: _submitting,
                        onPressed:
                            _acceptedTerms && !_submitting ? _handleSignUp : null,
                      ),
                      const SizedBox(height: 18),

                      // Divider
                      const AuthDivider(text: 'o Regístrate con'),
                      const SizedBox(height: 18),

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
                      const SizedBox(height: 18),

                      // Login link
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(text: '¿Ya tienes cuenta? '),
                              TextSpan(
                                text: 'Inicia Sesión',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => context.go('/login'),
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
