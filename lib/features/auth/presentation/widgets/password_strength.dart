import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

enum PasswordStrength { none, weak, medium, strong }

final RegExp passwordUpperPattern = RegExp(r'[A-Z]');
final RegExp passwordNumberPattern = RegExp(r'[0-9]');
final RegExp passwordSpecialPattern = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

/// Scoring compartido entre Sign Up y Recuperacion de contrasena. Debe ser el
/// UNICO lugar que define la fuerza de una clave para no divergir visualmente.
PasswordStrength getPasswordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.none;
  int score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 10) score++;
  if (passwordUpperPattern.hasMatch(password)) score++;
  if (passwordNumberPattern.hasMatch(password)) score++;
  if (passwordSpecialPattern.hasMatch(password)) score++;

  if (score <= 2) return PasswordStrength.weak;
  if (score <= 3) return PasswordStrength.medium;
  return PasswordStrength.strong;
}

/// Indicador de puntos acumulativos: debil = 1 rojo, media = 2 naranjas,
/// fuerte = todos verdes. Mismo componente que usa Sign Up.
class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;

  const PasswordStrengthIndicator({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    final isStrong = strength == PasswordStrength.strong;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(
          active: strength != PasswordStrength.none,
          color: isStrong ? AppColors.strengthStrong : AppColors.strengthWeak,
        ),
        const SizedBox(width: 3),
        _Dot(
          active: strength == PasswordStrength.medium || isStrong,
          color: isStrong ? AppColors.strengthStrong : AppColors.strengthMedium,
        ),
        const SizedBox(width: 3),
        _Dot(
          active: strength == PasswordStrength.medium || isStrong,
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

  String _getStrengthText(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.none:
        return '';
      case PasswordStrength.weak:
        return 'Débil';
      case PasswordStrength.medium:
        return 'Media';
      case PasswordStrength.strong:
        return 'Fuerte';
    }
  }

  Color _getStrengthColor(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.none:
        return AppColors.textGray;
      case PasswordStrength.weak:
        return AppColors.strengthWeak;
      case PasswordStrength.medium:
        return AppColors.strengthMedium;
      case PasswordStrength.strong:
        return AppColors.strengthStrong;
    }
  }
}

/// Muestra los requisitos que le faltan a la contrasena en tiempo real.
class PasswordHintsList extends StatelessWidget {
  final String password;

  const PasswordHintsList({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final hasUpper = passwordUpperPattern.hasMatch(password);
    final hasNumber = passwordNumberPattern.hasMatch(password);
    final hasSpecial = passwordSpecialPattern.hasMatch(password);
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