import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

import '../../domain/models/training_session.dart';
import '../controllers/training_storage_providers.dart';

class CardioSessionPage extends ConsumerStatefulWidget {
  const CardioSessionPage({super.key});

  @override
  ConsumerState<CardioSessionPage> createState() => _CardioSessionPageState();
}

class _CardioSessionPageState extends ConsumerState<CardioSessionPage>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('rivalfit/cardio');
  static const _events = EventChannel('rivalfit/cardio_steps');
  final _clock = Stopwatch();
  StreamSubscription<dynamic>? _stepsSubscription;
  Future<void>? _stopping;
  DateTime? _startedAt;
  TrainingSessionResult? _result;
  int _steps = 0;
  bool _starting = false;
  bool _saving = false;
  bool _saved = false;
  bool _exitDialogOpen = false;
  String? _message;

  bool get _running => _stepsSubscription != null;
  bool _inForeground(AppLifecycleState? state) =>
      state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_inForeground(state) && _running) {
      unawaited(_pause());
    }
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _message = null;
    });
    try {
      await _stopping;
      final status = await _channel.invokeMethod<String>('prepare');
      if (!mounted) return;
      if (status != 'ready') {
        setState(() => _message = _sensorMessage(status));
        return;
      }
      if (!_inForeground(WidgetsBinding.instance.lifecycleState)) {
        return;
      }
      _startedAt ??= DateTime.now().toUtc();
      _clock.start();
      _stepsSubscription = _events.receiveBroadcastStream().listen(
        (event) {
          if (mounted && _running && event == 1) setState(() => _steps++);
        },
        onError: (Object error) {
          if (!mounted) return;
          unawaited(_pause());
          setState(
            () => _message = _sensorMessage(
              error is PlatformException ? error.code : null,
            ),
          );
        },
      );
    } catch (_) {
      if (mounted) setState(() => _message = _sensorMessage(null));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  String _sensorMessage(String? status) => switch (status) {
    'denied' => 'Permite Actividad física en los ajustes del teléfono.',
    _ => 'El sensor de pasos no está disponible en este teléfono.',
  };

  Future<void> _pause() {
    final subscription = _stepsSubscription;
    if (subscription == null) return _stopping ?? Future.value();
    _clock.stop();
    setState(() => _stepsSubscription = null);
    return _stopping = subscription.cancel().catchError((Object _) {});
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await _pause();
      if (!mounted) return;
      final start = _startedAt!;
      final end = DateTime.now().toUtc();
      final minimumEnd = start.add(_clock.elapsed);
      final result = _result ??= TrainingSessionResult(
        sessionId: createTrainingSessionId(),
        exerciseId: 'cardio',
        rulesVersion: 'cardio-pasos-v1',
        source: TrainingSource.stepSensor,
        startedAtUtc: start,
        endedAtUtc: end.isBefore(minimumEnd) ? minimumEnd : end,
        activeDuration: _clock.elapsed,
        validReps: 0,
        steps: _steps,
      );
      if (result.eligibleForLocalHistory) {
        final repository = await ref.read(
          trainingSessionRepositoryProvider.future,
        );
        if (repository == null) throw StateError('No session account');
        await repository.complete(result);
      }
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'No se pudo guardar. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmExit() async {
    if (_exitDialogOpen) return;
    _exitDialogOpen = true;
    await _pause();
    if (!mounted) return;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Terminar cardio?'),
        content: Text('Tienes $_steps pasos registrados en esta sesión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar sesión'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;
    if (!mounted) return;
    if (save == true) await _finish();
    if (save == false && mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final subscription = _stepsSubscription;
    _stepsSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel().catchError((Object _) {}));
    }
    _clock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(trainingSessionRepositoryProvider);
    final started = _startedAt != null;
    final locked = _starting || _saving;
    return PopScope(
      canPop: !locked && (_steps == 0 || _saved),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !locked && !_saved && _steps > 0) {
          unawaited(_confirmExit());
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Cardio')),
        body: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.carbon,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.directions_run_rounded,
                                size: 52,
                                color: AppColors.volt,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                started ? '$_steps' : 'Conteo de pasos',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.volt,
                                  fontSize: started ? 66 : 30,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              if (started) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _steps == 1 ? 'Paso' : 'Pasos',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _message ??
                              (_saved
                                  ? (_steps > 0
                                        ? 'Sesión guardada en este teléfono.'
                                        : 'No se registraron pasos.')
                                  : started
                                  ? (_running
                                        ? 'Sesión en curso'
                                        : 'Sesión en pausa')
                                  : 'Camina o corre con el teléfono contigo. Mantén RivalFit abierto durante la sesión.'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: locked
                        ? null
                        : _saved
                        ? () => Navigator.of(context).pop()
                        : _result != null
                        ? _finish
                        : _running
                        ? _pause
                        : _start,
                    child: Text(
                      _saving
                          ? 'Guardando…'
                          : _starting
                          ? 'Preparando sensor…'
                          : _saved
                          ? 'Volver a Entrenar'
                          : _result != null
                          ? 'Guardar sesión'
                          : _running
                          ? 'Pausar'
                          : started
                          ? 'Reanudar'
                          : 'Empezar cardio',
                    ),
                  ),
                  if (started && !_saved && _result == null)
                    TextButton(
                      onPressed: locked ? null : _finish,
                      child: const Text('Terminar sesión'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
