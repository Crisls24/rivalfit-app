import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/features/auth/domain/repositories/auth_repository.dart';

const int recoveryOtpLength = 6;

/// Duración del cooldown de reenvío en segundos. Coincide con el límite SMTP
/// de GoTrue (1 email/min por usuario) para no chocar con el rate-limit.
const int recoveryResendCooldown = 60;

enum RecoveryStep { email, otp, password, success }

class RecoveryState {
  final RecoveryStep step;
  final bool isSubmitting;
  final String? email;
  final String maskedEmail;
  final int cooldownSeconds;
  final String? errorMessage;

  /// Código que la UI debe prellenar en el paso OTP (auto-relleno desde el
  /// enlace del correo). Se consume una sola vez: se descarta al verificar.
  final String? prefillCode;

  /// True una vez que la clave se actualizó y se cerró la sesión temporal.
  /// Lo consume el Login para mostrar el mensaje de éxito y luego se resetea.
  final bool justCompleted;

  const RecoveryState({
    this.step = RecoveryStep.email,
    this.isSubmitting = false,
    this.email,
    this.maskedEmail = '',
    this.cooldownSeconds = 0,
    this.errorMessage,
    this.prefillCode,
    this.justCompleted = false,
  });

  RecoveryState copyWith({
    RecoveryStep? step,
    bool? isSubmitting,
    String? email,
    String? maskedEmail,
    int? cooldownSeconds,
    Object? errorMessage = _unset,
    Object? prefillCode = _unset,
    bool? justCompleted,
  }) {
    return RecoveryState(
      step: step ?? this.step,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      email: email ?? this.email,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      prefillCode: identical(prefillCode, _unset)
          ? this.prefillCode
          : prefillCode as String?,
      justCompleted: justCompleted ?? this.justCompleted,
    );
  }

  static const _unset = Object();
}

class RecoveryController extends StateNotifier<RecoveryState> {
  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  final AuthRepository _repo;
  Timer? _cooldownTimer;

  RecoveryController(this._repo) : super(const RecoveryState());

  /// Estado 1 -> 2. Envia el codigo real a traves de GoTrue. Para emails
  /// inexistentes el backend responde igual (anti-enumeracion), asi que el
  /// flujo siempre avanza a "Revisa tu correo" si la solicitud fue aceptada.
  Future<void> requestCode(String email) async {
    final trimmed = email.trim();
    if (!_emailRegex.hasMatch(trimmed)) {
      state = state.copyWith(errorMessage: 'Ingresa un correo válido');
      return;
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final error = await _repo.sendRecoveryCode(trimmed);
    if (error != null) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
      return;
    }
    state = state.copyWith(
      isSubmitting: false,
      step: RecoveryStep.otp,
      email: trimmed,
      maskedEmail: maskEmail(trimmed),
      errorMessage: null,
    );
    _startCooldown();
  }

  /// Entra directo al paso OTP con un código recibido por deep link (el correo
  /// abre la app con email + código). Arranca el cooldown para que el reenvío
  /// respete el límite SMTP de GoTrue.
  void startFromLink({required String email, required String code}) {
    final trimmed = email.trim();
    if (trimmed.isEmpty || code.length != recoveryOtpLength) return;
    _cooldownTimer?.cancel();
    state = RecoveryState(
      step: RecoveryStep.otp,
      email: trimmed,
      maskedEmail: maskEmail(trimmed),
      prefillCode: code,
    );
    _startCooldown();
  }

  /// Estado 2 -> 3. Valida los 6 digitos automaticamente al completarlos.
  Future<void> verifyCode(String code) async {
    if (code.length != recoveryOtpLength || state.isSubmitting) return;
    final email = state.email;
    if (email == null) return;

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final error = await _repo.verifyRecoveryCode(email: email, code: code);
    if (error != null) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
      return;
    }
    state = state.copyWith(
      isSubmitting: false,
      step: RecoveryStep.password,
      errorMessage: null,
      prefillCode: null,
    );
  }

  /// Reenvio sujeto al cooldown de 60s (límite SMTP de GoTrue).
  Future<void> resendCode() async {
    if (state.cooldownSeconds > 0 || state.isSubmitting) return;
    final email = state.email;
    if (email == null) return;
    await requestCode(email);
  }

  /// Estado 3 -> exito. Actualiza la clave bajo la sesion temporal de recovery
  /// y la descarta (signOut) para no dejar una sesion residual.
  Future<void> changePassword(String newPassword) async {
    if (state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final error = await _repo.resetPassword(newPassword);
    if (error != null) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
      return;
    }
    _cooldownTimer?.cancel();
    state = RecoveryState(
      step: RecoveryStep.success,
      email: state.email,
      maskedEmail: state.maskedEmail,
      justCompleted: true,
    );
  }

  /// Navegacion hacia atras dentro de la misma experiencia (sin salir).
  void back() {
    if (state.step == RecoveryStep.otp) {
      state = state.copyWith(
        step: RecoveryStep.email,
        errorMessage: null,
        prefillCode: null,
      );
    } else if (state.step == RecoveryStep.password) {
      state = state.copyWith(step: RecoveryStep.otp, errorMessage: null);
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Regresa al estado inicial. Lo usa el Login tras consumir justCompleted.
  void reset() {
    _cooldownTimer?.cancel();
    state = const RecoveryState();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    state = state.copyWith(cooldownSeconds: recoveryResendCooldown);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.cooldownSeconds - 1;
      if (next <= 0) {
        timer.cancel();
        state = state.copyWith(cooldownSeconds: 0);
      } else {
        state = state.copyWith(cooldownSeconds: next);
      }
    });
  }
}

/// Oculta el correo manteniendo la primera letra y el dominio.
/// Ejemplo: crfewr@gmail.com -> c***@gmail.com
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  final local = email.substring(0, at);
  final domain = email.substring(at);
  final head = local.isEmpty ? '' : local[0];
  final maskLen = local.length <= 1 ? 1 : (local.length <= 3 ? 2 : 3);
  return '$head${'*' * maskLen}$domain';
}