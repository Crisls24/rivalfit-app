import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

class DailyStepsCard extends StatefulWidget {
  const DailyStepsCard({super.key});

  @override
  State<DailyStepsCard> createState() => _DailyStepsCardState();
}

class _DailyStepsCardState extends State<DailyStepsCard>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('rivalfit/daily_steps');
  static const _stepControl = MethodChannel('rivalfit/cardio');
  static const _stepEvents = EventChannel('rivalfit/cardio_steps');
  static const _appSettings = MethodChannel('rivalfit/app_settings');
  static const _goal = 6000;
  Timer? _timer;
  StreamSubscription<dynamic>? _liveSubscription;
  String _status = 'loading';
  int? _steps;
  int _liveBase = 0;
  int _liveDelta = 0;
  int _estimate = 0;
  DateTime? _readDay;
  bool _working = false;
  bool _denied = false;
  bool _startingLive = false;
  bool _visible = false;
  bool _foreground = true;
  bool _attemptedLive = false;
  bool _livePermissionDenied = false;
  bool get _canShowLive =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _resume() {
    if (!_visible || !_foreground) return;
    _attemptedLive = false;
    unawaited(_refresh());
    _timer ??= Timer.periodic(const Duration(seconds: 20), (_) {
      if (_status == 'ready' ||
          _status == 'needsSource' ||
          _status == 'error') {
        unawaited(_refresh());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (state == AppLifecycleState.resumed) {
      _resume();
    } else if (!_foreground) {
      _timer?.cancel();
      _timer = null;
      _cancelLive();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (visible == _visible) return;
    _visible = visible;
    if (visible) {
      _resume();
    } else {
      _timer?.cancel();
      _timer = null;
      _cancelLive();
    }
  }

  Future<void> _startLive() async {
    if (!_canShowLive ||
        !_visible ||
        !_foreground ||
        _steps == null ||
        _startingLive ||
        _attemptedLive ||
        _liveSubscription != null) {
      return;
    }
    _startingLive = true;
    _attemptedLive = true;
    try {
      final status = await _stepControl.invokeMethod<String>('prepareDaily');
      final steps = _steps;
      if (!mounted ||
          !_visible ||
          !_foreground ||
          _status != 'ready' ||
          steps == null) {
        return;
      }
      if (_livePermissionDenied != (status == 'denied')) {
        setState(() => _livePermissionDenied = status == 'denied');
      }
      if (status != 'ready') return;
      _liveBase = math.max(steps, _estimate);
      _liveDelta = 0;
      _liveSubscription = _stepEvents
          .receiveBroadcastStream(false)
          .listen(
            (event) {
              if (!mounted || event is! int || event < 1 || event > 3) return;
              if (!DateUtils.isSameDay(_readDay, DateTime.now())) {
                unawaited(_refresh());
                return;
              }
              setState(() {
                _liveDelta += event;
                _estimate = math.max(_estimate, _liveBase + _liveDelta);
              });
            },
            onError: (Object error) {
              _cancelLive();
              if (mounted &&
                  error is PlatformException &&
                  error.code == 'denied') {
                setState(() => _livePermissionDenied = true);
              }
            },
            onDone: _cancelLive,
          );
    } catch (_) {
      // Health Connect still supplies the daily total on its own.
    } finally {
      _startingLive = false;
    }
  }

  void _cancelLive() {
    final subscription = _liveSubscription;
    _liveSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel().catchError((Object _) {}));
    }
  }

  Future<Map<Object?, Object?>> _invoke(String method) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const {'status': 'unsupported'};
    }
    try {
      final response = _channel.invokeMapMethod<Object?, Object?>(method);
      final result = method == 'requestAccess'
          ? await response
          : await response.timeout(const Duration(seconds: 15));
      return result ?? const {'status': 'error'};
    } on MissingPluginException {
      return const {'status': 'unsupported'};
    } catch (_) {
      return const {'status': 'error'};
    }
  }

  Future<void> _refresh([String method = 'today']) async {
    if (_working || !mounted) return;
    final day = DateTime.now();
    final newDay = !DateUtils.isSameDay(_readDay, day);
    if (newDay && _liveSubscription != null) {
      _cancelLive();
      _attemptedLive = false;
    }
    final subscription = _liveSubscription;
    final deltaAtRequest = _liveDelta;
    setState(() {
      _working = true;
      if (newDay) {
        _estimate = 0;
        _steps = null;
      }
    });
    var reply = await _invoke(method);
    if (!mounted) return;
    if (reply['status'] == 'granted') {
      reply = await _invoke('today');
      if (!mounted) return;
    }
    setState(() {
      _working = false;
      final status = reply['status'] as String;
      if (status == 'settingsOpened') return;
      if (status == 'error' && _steps != null) return;
      if (status == 'denied') _denied = true;
      if (status == 'ready' || status == 'needsSource') _denied = false;
      _status = status == 'denied' ? 'permission' : status;
      _steps = reply['steps'] as int?;
      _readDay = day;
      final confirmed = _steps;
      if (status == 'ready' && confirmed != null) {
        // A Health Connect batch can contain steps already shown by the sensor.
        // Rebase only once the confirmed total reaches the earlier estimate.
        if (subscription != null &&
            identical(subscription, _liveSubscription) &&
            deltaAtRequest == _liveDelta &&
            confirmed >= _liveBase + deltaAtRequest) {
          _liveBase = confirmed;
          _liveDelta -= deltaAtRequest;
          _estimate = math.max(_estimate, _liveBase + _liveDelta);
        }
        _estimate = math.max(_estimate, confirmed);
      } else {
        _cancelLive();
        _attemptedLive = false;
        _estimate = 0;
      }
    });
    if (!DateUtils.isSameDay(day, DateTime.now())) {
      await _refresh();
    } else if (_status == 'ready') {
      unawaited(_startLive());
    }
  }

  Future<void> _openActivitySettings() async {
    try {
      await _appSettings.invokeMethod<void>('open');
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abre los permisos de RivalFit en Ajustes.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _cancelLive();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _status == 'ready' && _steps != null;
    final (detail, actionLabel, method) = switch (_status) {
      'permission' when _denied => (
        'Da acceso a tus pasos desde Health Connect.',
        'Abrir ajustes',
        'openSettings',
      ),
      'permission' => (
        'Conecta tus pasos para ver tu actividad aunque cierres RivalFit.',
        'Conectar pasos',
        'requestAccess',
      ),
      'needsSource' => (
        'Vincula una app o un dispositivo que registre tus pasos en Health Connect.',
        'Abrir Health Connect',
        'openSettings',
      ),
      'unsupported' => (
        'Disponible en Android 14 o posterior con Health Connect.',
        null,
        'today',
      ),
      'error' => (
        'Volveremos a consultar tus pasos en un momento.',
        null,
        'today',
      ),
      _ => (null, null, 'today'),
    };
    final format = MaterialLocalizations.of(context).formatDecimal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pasos de hoy',
          style: TextStyle(
            color: AppColors.carbon,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (ready) ...[
          const SizedBox(height: 4),
          Text(
            format(_estimate),
            style: const TextStyle(
              color: AppColors.carbon,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _estimate >= _goal ? 'Meta cumplida' : 'Meta ${format(_goal)}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: (_estimate / _goal).clamp(0.0, 1.0),
            color: AppColors.volt,
            backgroundColor: const Color(0xFFE1E1DF),
            borderRadius: BorderRadius.circular(8),
            minHeight: 6,
            semanticsLabel: 'Avance de pasos',
          ),
          if (_livePermissionDenied)
            TextButton(
              onPressed: _openActivitySettings,
              child: const Text('Permitir actividad física'),
            ),
        ],
        if (detail != null) ...[
          const SizedBox(height: 5),
          Text(
            detail,
            style: const TextStyle(color: AppColors.grayMain, fontSize: 12),
          ),
        ] else if (_status == 'loading') ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            color: AppColors.volt,
            backgroundColor: AppColors.subtleBorder,
            minHeight: 2,
          ),
        ],
        if (actionLabel != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.carbon,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            onPressed: _working ? null : () => _refresh(method),
            child: Text(actionLabel),
          ),
      ],
    );
  }
}
