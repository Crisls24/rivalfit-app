import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

import '../controllers/training_session_controller.dart';
import '../controllers/training_camera_controller.dart';
import '../widgets/training_setup_guide.dart';
import '../widgets/training_camera_panel.dart';
import '../controllers/training_storage_providers.dart';
import '../../data/repositories/training_session_repository.dart';
import '../../domain/models/saved_training_session.dart';
import '../../domain/models/training_session.dart';

/// Guided Android squat session with a live camera preview.
class TrainingSessionPage extends ConsumerStatefulWidget {
  final bool fromLeague;
  final TrainingMovement movement;

  const TrainingSessionPage({
    super.key,
    this.fromLeague = false,
    this.movement = TrainingMovement.squat,
  });

  @override
  ConsumerState<TrainingSessionPage> createState() =>
      _TrainingSessionPageState();
}

class _TrainingSessionPageState extends ConsumerState<TrainingSessionPage>
    with WidgetsBindingObserver {
  late final _session = TrainingSessionController(movement: widget.movement);
  bool get _isPlank => widget.movement == TrainingMovement.plank;
  int get _measurement =>
      _isPlank ? _session.holdDuration.inSeconds : _session.reps;
  String get _unit => _isPlank
      ? (_measurement == 1 ? 'Segundo en plancha' : 'Segundos en plancha')
      : (_measurement == 1 ? 'Repetición' : 'Repeticiones');
  late final TrainingCameraController _camera;
  TrainingPhase _previousPhase = TrainingPhase.preparation;
  bool _exitDialogOpen = false;
  bool _allowExit = false;
  TrainingSessionRepository? _repository;
  Timer? _checkpointTimer;
  Future<void> _saveChain = Future.value();
  int _queuedWrites = 0;
  bool _discarding = false;
  String? _storageError;
  final _preferences = SharedPreferencesAsync();
  String get _guideLabel =>
      'Ver guía de ${widget.movement.label.toLowerCase()}';
  static const _audioKey = 'training.audioEnabled';
  static const _audioChannel = MethodChannel('rivalfit/training_audio');
  bool _cameraRequested = false;
  bool _audioEnabled = true;
  bool _foreground = true;
  bool _autoStart = true;
  Timer? _countdown;
  int? _seconds;
  int _previousReps = 0;
  Timer? _repFeedbackTimer;

  @override
  void initState() {
    super.initState();
    _camera = TrainingCameraController(
      onObservation: _session.processObservation,
      movement: widget.movement,
    );
    WidgetsBinding.instance.addObserver(this);
    _session.addListener(_onSessionChanged);
    _camera.addListener(_onCameraChanged);
    unawaited(_loadPreferences());
    unawaited(_prepareStorage());
    _checkpointTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_session.phase == TrainingPhase.active) unawaited(_saveSnapshot());
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final audio = await _preferences.getBool(_audioKey) ?? true;
      if (!mounted) return;
      setState(() => _audioEnabled = audio);
    } on Exception {
      // The audio toggle remains available without stored preferences.
    }
  }

  void _showSetupGuide() {
    _cancelCountdown();
    setState(() => _cameraRequested = false);
    _session.updatePosture(ready: false);
    unawaited(_camera.deactivate());
  }

  void _openCamera() {
    setState(() {
      _cameraRequested = true;
      _autoStart = true;
    });
    if (_foreground) unawaited(_camera.activate());
  }

  void _startAnotherSeries() {
    if (_session.phase != TrainingPhase.finished ||
        _queuedWrites > 0 ||
        _storageError != null ||
        _closingCamera) {
      return;
    }
    _session.prepareAnotherSeries();
    _openCamera();
  }

  bool get _closingCamera =>
      _camera.status == TrainingCameraStatus.ready ||
      _camera.status == TrainingCameraStatus.loading;

  Future<void> _savePreference(String key, bool value) async {
    try {
      await _preferences.setBool(key, value);
    } on Exception {
      // Keep the preference for this session.
    }
  }

  Future<void> _playCue(String cue) async {
    if (!_audioEnabled || !_foreground) return;
    try {
      await _audioChannel.invokeMethod<void>(cue);
    } on Exception {
      // Training remains available without device audio.
    }
  }

  bool get _canStart =>
      _foreground &&
      _cameraRequested &&
      _session.phase == TrainingPhase.preparation &&
      _camera.status == TrainingCameraStatus.ready &&
      _session.postureReady &&
      _repository != null;

  void _refreshCountdown() {
    if (!_canStart || !_autoStart) {
      _cancelCountdown();
      return;
    }
    if (_countdown != null) return;
    setState(() => _seconds = 3);
    unawaited(_playCue('ready'));
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_canStart) {
        _cancelCountdown();
      } else if (_seconds == 1) {
        _cancelCountdown();
        _session.start();
      } else {
        setState(() => _seconds = _seconds! - 1);
        unawaited(_playCue('ready'));
      }
    });
  }

  void _cancelCountdown() {
    _countdown?.cancel();
    _countdown = null;
    if (_seconds != null && mounted) setState(() => _seconds = null);
  }

  Future<void> _prepareStorage() async {
    try {
      final repository = await ref.read(
        trainingSessionRepositoryProvider.future,
      );
      if (repository == null) throw StateError('No session account');
      await repository.load();
      if (mounted) {
        setState(() {
          _repository = repository;
          _storageError = null;
        });
        _refreshCountdown();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _storageError =
              'No se pudo preparar el guardado. Inténtalo de nuevo.',
        );
      }
    }
  }

  Future<void> _saveSnapshot() {
    if (_discarding) return Future.value();
    final snapshot = _session.checkpoint();
    final repository = _repository;
    if (snapshot == null || repository == null) return Future.value();
    final finished = _session.phase == TrainingPhase.finished;
    _queuedWrites++;
    if (mounted) setState(() => _storageError = null);
    _saveChain = _saveChain.then((_) async {
      try {
        if (finished) {
          await repository.complete(snapshot);
        } else {
          await repository.checkpoint(snapshot);
        }
        if (mounted) setState(() => _storageError = null);
      } catch (_) {
        if (mounted) {
          setState(
            () => _storageError = 'No se pudo guardar en este teléfono. Reintenta antes de salir.',
          );
        }
      } finally {
        _queuedWrites--;
        if (mounted) setState(() {});
      }
    });
    return _saveChain;
  }

  Future<void> _retrySessionSync() async {
    try {
      await _repository?.sync(force: true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo reintentar la sincronización.'),
        ),
      );
    }
  }

  void _onCameraChanged() {
    if (_camera.status == TrainingCameraStatus.ready) {
      _refreshCountdown();
    } else {
      _session.updatePosture(ready: false);
    }
  }

  void _onSessionChanged() {
    _refreshCountdown();
    final phase = _session.phase;
    if (phase != TrainingPhase.active) {
      _repFeedbackTimer?.cancel();
      _repFeedbackTimer = null;
    } else if (_session.reps > _previousReps) {
      _repFeedbackTimer?.cancel();
      _repFeedbackTimer = Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _repFeedbackTimer = null);
      });
      unawaited(_playCue('rep'));
    }
    _previousReps = _session.reps;
    if (_previousPhase != phase) {
      final previous = _previousPhase;
      _previousPhase = phase;
      if (phase == TrainingPhase.active &&
          (previous == TrainingPhase.preparation ||
              previous == TrainingPhase.recovering)) {
        unawaited(_playCue('start'));
      } else if (previous == TrainingPhase.active &&
          phase == TrainingPhase.recovering) {
        unawaited(_playCue('lost'));
      }
      unawaited(_saveSnapshot());
      if (phase == TrainingPhase.paused || phase == TrainingPhase.finished) {
        unawaited(_camera.deactivate());
      } else if (previous == TrainingPhase.paused && _foreground) {
        unawaited(_camera.activate());
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _cancelCountdown();
      _session.pause();
      if (_session.phase == TrainingPhase.preparation) {
        _session.updatePosture(ready: false);
      }
      unawaited(_camera.deactivate());
    } else if (_cameraRequested &&
        _session.phase != TrainingPhase.finished &&
        _session.phase != TrainingPhase.paused) {
      unawaited(_camera.activate());
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(
        _repository?.sync().catchError((Object _) {}) ?? Future.value(),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkpointTimer?.cancel();
    _countdown?.cancel();
    _repFeedbackTimer?.cancel();
    _session.removeListener(_onSessionChanged);
    _camera.removeListener(_onCameraChanged);
    _camera.dispose();
    _session.dispose();
    super.dispose();
  }

  void _leave() {
    _autoStart = false;
    _cancelCountdown();
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(widget.fromLeague ? '/home?tab=league' : '/home');
      }
    });
  }

  Future<void> _requestExit() async {
    if (_exitDialogOpen) return;
    if (!_session.inProgress) {
      if (_queuedWrites > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estamos guardando tu sesión…')),
        );
        return;
      }
      if (_session.phase == TrainingPhase.finished && _storageError != null) {
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('La sesión aún no se guardó'),
            content: const Text(
              'Si sales ahora podrías perder el resultado. Puedes quedarte y reintentar.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Quedarme'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Salir de todos modos'),
              ),
            ],
          ),
        );
        if (!mounted || leave != true) return;
      }
      _leave();
      return;
    }
    _session.pause();
    _exitDialogOpen = true;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Qué hacemos con tu sesión?'),
        content: const Text('El entrenamiento está pausado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'stay'),
            child: const Text('Seguir aquí'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'finish'),
            child: const Text('Terminar'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;
    if (!mounted) return;
    if (action == 'discard') {
      _discarding = true;
      await _saveChain;
      try {
        final id = _session.sessionId;
        if (id != null) await _repository?.discardDraft(id);
        if (mounted) _leave();
      } catch (_) {
        _discarding = false;
        if (mounted) {
          setState(
            () => _storageError = 'No se pudo descartar. Inténtalo de nuevo.',
          );
        }
      }
    }
    if (action == 'finish') _session.finish();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(trainingSessionRepositoryProvider);
    final saved = ref.watch(savedTrainingSessionsProvider).valueOrNull ?? [];
    final colors = ColorScheme.fromSeed(
      seedColor: AppColors.volt,
      primary: AppColors.carbon,
      surface: Colors.white,
      error: AppColors.danger,
    );
    final theme = ThemeData(
      colorScheme: colors,
      textTheme: Theme.of(context).textTheme
          .apply(bodyColor: AppColors.carbon, displayColor: AppColors.carbon),
    );
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final phase = _session.phase;
        final finished = phase == TrainingPhase.finished;
        final showingGuide = !finished && !_cameraRequested;
        final background = showingGuide
            ? Colors.white
            : AppColors.iceBackground;
        final record = finished
            ? saved
                  .where((r) => r.result.sessionId == _session.sessionId)
                  .firstOrNull
            : null;
        return PopScope(
          canPop:
              _allowExit ||
              (!_session.inProgress &&
                  _queuedWrites == 0 &&
                  !(_session.phase == TrainingPhase.finished &&
                      _storageError != null)),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_requestExit());
          },
          child: Theme(
            data: theme,
            child: Scaffold(
              backgroundColor: background,
              appBar: AppBar(
                backgroundColor: background,
                foregroundColor: AppColors.carbon,
                scrolledUnderElevation: showingGuide ? 0 : null,
                toolbarHeight: showingGuide ? 64 : null,
                titleTextStyle: showingGuide
                    ? const TextStyle(
                        color: AppColors.carbon,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                      )
                    : null,
                leading: IconButton(
                  onPressed: _requestExit,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                title: Text(widget.movement.label),
                actions: [
                  if (phase == TrainingPhase.preparation && _cameraRequested)
                    IconButton(
                      tooltip: _guideLabel,
                      icon: const Icon(Icons.help_outline_rounded),
                      onPressed: _showSetupGuide,
                    ),
                  if (!finished)
                    IconButton(
                      tooltip: _audioEnabled
                          ? 'Silenciar avisos'
                          : 'Activar avisos sonoros',
                      icon: Icon(
                        _audioEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                      ),
                      onPressed: () {
                        setState(() => _audioEnabled = !_audioEnabled);
                        unawaited(_savePreference(_audioKey, _audioEnabled));
                      },
                    ),
                ],
              ),
              body: finished
                  ? _resultPanel(record)
                  : SafeArea(
                      child: _cameraRequested
                          ? _cameraStage(phase)
                          : TrainingSetupGuide(
                              movement: widget.movement,
                              onStart: _openCamera,
                              audioEnabled: _audioEnabled,
                            ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _cameraStage(TrainingPhase phase) => LayoutBuilder(
    builder: (context, constraints) {
      final preview = TrainingCameraPanel(
        controller: _camera,
        countdown: _seconds,
        paused: phase == TrainingPhase.paused,
      );
      final footer = ListenableBuilder(
        listenable: _camera,
        builder: (context, _) => _sessionControls(phase),
      );
      final needsScroll =
          constraints.maxHeight < 440 ||
          MediaQuery.textScalerOf(context).scale(16) > 24;
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (needsScroll)
            SizedBox(height: 240, child: preview)
          else
            Expanded(child: preview),
          const SizedBox(height: 8),
          footer,
        ],
      );
      const padding = EdgeInsets.fromLTRB(16, 4, 16, 12);
      return needsScroll
          ? SingleChildScrollView(padding: padding, child: content)
          : Padding(padding: padding, child: content);
    },
  );

  Widget _sessionControls(TrainingPhase phase) {
    final preparation = phase == TrainingPhase.preparation;
    final paused = phase == TrainingPhase.paused;
    final cameraLive = _camera.status == TrainingCameraStatus.ready && !paused;
    final String? instruction = switch (phase) {
      _ when !cameraLive => null,
      TrainingPhase.preparation when _seconds != null => null,
      TrainingPhase.preparation when !_autoStart => 'Inicio en pausa.',
      TrainingPhase.preparation
          when _repository == null &&
              _storageError == null &&
              _session.postureReady =>
        'Preparando la sesión.',
      _ => _session.feedback,
    };
    if (preparation &&
        instruction == null &&
        _seconds == null &&
        _storageError == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carbon,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (!preparation) ...[
                Flexible(
                  flex: 2,
                  child: Semantics(
                    label: '$_measurement ${_unit.toLowerCase()}',
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$_measurement',
                        style: const TextStyle(
                          color: AppColors.volt,
                          fontSize: 88,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!preparation)
                      Semantics(
                        liveRegion: _repFeedbackTimer != null,
                        child: Text(
                          _repFeedbackTimer != null
                              ? '✓ Repetición válida'
                              : _unit,
                          style: TextStyle(
                            color: _repFeedbackTimer != null
                                ? AppColors.volt
                                : Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (instruction != null)
                      Text(
                        instruction,
                        style: TextStyle(
                          color:
                              phase == TrainingPhase.recovering ||
                                  instruction == 'Fuera de cuadro'
                              ? AppColors.volt
                              : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_storageError case final error?)
            if (_repository == null)
              TextButton(
                onPressed: _prepareStorage,
                style: TextButton.styleFrom(foregroundColor: AppColors.volt),
                child: Text(error),
              )
            else
              Text(error, style: const TextStyle(color: Colors.white)),
          if (preparation && _seconds != null)
            TextButton(
              onPressed: () {
                _autoStart = false;
                _cancelCountdown();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Cancelar inicio'),
            )
          else if (preparation && !_autoStart && cameraLive)
            _primary('Iniciar cuenta regresiva', () {
              setState(() => _autoStart = true);
              _refreshCountdown();
            }),
          if (!preparation) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: paused ? _session.resume : _session.pause,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(paused ? 'Continuar' : 'Pausar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _primary('Terminar', _session.finish)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _primary(String label, VoidCallback? action) => FilledButton(
    onPressed: action,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.volt,
      foregroundColor: AppColors.carbon,
      minimumSize: const Size.fromHeight(56),
    ),
    child: Text(label),
  );

  Widget _resultPanel(SavedTrainingSession? record) => ListenableBuilder(
    listenable: _camera,
    builder: (context, _) {
      final saving = _queuedWrites > 0;
      final error = _storageError;
      final syncing = _repository?.syncing ?? false;
      final status = switch (record?.state) {
        _ when saving => 'Guardando sesión…',
        _ when error != null => error,
        _ when _measurement == 0 =>
          _isPlank
              ? 'No se registró tiempo en postura.'
              : 'Esta serie quedó sin repeticiones.',
        SavedSessionState.personal => 'Guardada en este teléfono',
        SavedSessionState.confirmed => 'Sesión sincronizada',
        SavedSessionState.rejected =>
          record?.error ?? 'No se pudo acreditar la sesión.',
        SavedSessionState.pending when syncing =>
          'Guardada en el teléfono. Sincronizando…',
        SavedSessionState.pending =>
          'Guardada en el teléfono. Pendiente de sincronizar.',
        _ => 'Comprobando el guardado de la sesión…',
      };

      return ColoredBox(
        color: AppColors.carbon,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Serie terminada',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_session.endedAfterTrackingLoss) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Pasaron 10 segundos sin poder seguir tu postura.',
                          style: TextStyle(color: AppColors.grayMain),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _resultMetrics(),
                      const SizedBox(height: 12),
                      Semantics(liveRegion: true, child: Text(status)),
                      if (_closingCamera ||
                          _camera.status == TrainingCameraStatus.idle)
                        Text(
                          _closingCamera
                              ? 'Cerrando cámara…'
                              : 'Cámara apagada',
                          style: const TextStyle(color: AppColors.grayMain),
                        ),
                      if (record?.state == SavedSessionState.confirmed)
                        _LeaguePoints(sessionId: record!.result.sessionId),
                      if (!saving &&
                          error == null &&
                          record?.state == SavedSessionState.pending &&
                          _repository?.remote.enabled == true)
                        TextButton(
                          onPressed: syncing ? null : _retrySessionSync,
                          child: const Text('Reintentar sincronización'),
                        ),
                      const SizedBox(height: 16),
                      if (error != null && !saving)
                        _primary('Reintentar guardado', _saveSnapshot)
                      else
                        _primary(
                          'Hacer otra serie',
                          saving || _closingCamera ? null : _startAnotherSeries,
                        ),
                      TextButton(
                        onPressed: saving ? null : _requestExit,
                        child: Text(
                          widget.fromLeague
                              ? 'Volver a Liga'
                              : 'Volver a Entrenar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _resultMetrics() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.iceBackground,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$_measurement',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_unit),
              Text(
                _activeTimeLabel,
                style: const TextStyle(color: AppColors.grayMain),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String get _activeTimeLabel {
    final duration = _session.activeDuration;
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds · tiempo activo';
  }
}

class _LeaguePoints extends ConsumerWidget {
  final String sessionId;

  const _LeaguePoints({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(trainingLeaguePointsProvider(sessionId));
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: points.when(
        data: (value) => Text(
          value == 0
              ? 'Esta sesión suma a tu progreso personal.'
              : '+$value ${value == 1 ? 'punto acreditado' : 'puntos acreditados'} en Liga',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        loading: () => const Text('Consultando los puntos de Liga…'),
        error: (_, _) => TextButton(
          onPressed: () =>
              ref.invalidate(trainingLeaguePointsProvider(sessionId)),
          child: const Text('Reintentar consulta de puntos'),
        ),
      ),
    );
  }
}
