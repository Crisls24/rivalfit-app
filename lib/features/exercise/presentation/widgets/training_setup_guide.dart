import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:video_player/video_player.dart';

import '../../domain/models/training_session.dart';

class TrainingSetupGuide extends StatefulWidget {
  const TrainingSetupGuide({
    super.key,
    required this.movement,
    required this.onStart,
    this.audioEnabled = true,
  });

  final TrainingMovement movement;
  final VoidCallback onStart;
  final bool audioEnabled;

  @override
  State<TrainingSetupGuide> createState() => _TrainingSetupGuideState();
}

class _TrainingSetupGuideState extends State<TrainingSetupGuide>
    with WidgetsBindingObserver {
  VideoPlayerController? _video;
  Animation<double>? _routeAnimation;
  bool _openingCamera = false;
  bool _videoUnavailable = false;
  bool _foreground = true;
  int _playRequest = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDemo();
  }

  void _loadDemo() {
    if (widget.movement != TrainingMovement.squat) return;
    final video = VideoPlayerController.asset('assets/videos/sentadillas.mp4');
    _video = video;
    unawaited(_initialize(video));
  }

  Future<void> _initialize(VideoPlayerController video) async {
    try {
      await video.initialize();
      if (mounted && identical(_video, video)) {
        await video.setVolume(widget.audioEnabled ? 1 : 0);
      }
    } catch (_) {
      if (mounted && identical(_video, video)) {
        setState(() => _videoUnavailable = true);
      }
    }
  }

  @override
  void didUpdateWidget(covariant TrainingSetupGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movement != widget.movement) {
      _releaseDemo();
      _videoUnavailable = false;
      _loadDemo();
    } else if (oldWidget.audioEnabled != widget.audioEnabled &&
        _video?.value.isInitialized == true) {
      unawaited(_setDemoVolume(_video!));
    }
  }

  Future<void> _setDemoVolume(VideoPlayerController video) async {
    try {
      await video.setVolume(widget.audioEnabled ? 1 : 0);
    } on Exception {
      // A player being released can no longer accept settings.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (!identical(animation, _routeAnimation)) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _routeAnimation = animation;
      _routeAnimation?.addStatusListener(_onRouteStatus);
    }
    if (ModalRoute.isCurrentOf(context) == false) {
      unawaited(_pauseDemo());
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse) unawaited(_pauseDemo());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) unawaited(_pauseDemo());
  }

  Future<void> _toggleDemo() async {
    final video = _video;
    if (_openingCamera ||
        !_foreground ||
        video == null ||
        !video.value.isInitialized) {
      return;
    }
    final request = ++_playRequest;
    try {
      if (video.value.isPlaying) {
        await video.pause();
      } else {
        await video.setVolume(widget.audioEnabled ? 1 : 0);
        if (mounted &&
            request == _playRequest &&
            identical(_video, video) &&
            !_openingCamera &&
            ModalRoute.isCurrentOf(context) != false) {
          await video.play();
        }
      }
    } on Exception {
      if (mounted && identical(_video, video)) {
        setState(() => _videoUnavailable = true);
      }
    }
  }

  Future<void> _pauseDemo() async {
    _playRequest++;
    final video = _video;
    if (video == null || !video.value.isPlaying) return;
    try {
      await video.pause();
    } on Exception {
      // Disposing the player also stops playback.
    }
  }

  Future<void> _startCamera() async {
    if (_openingCamera) return;
    _openingCamera = true;
    await _pauseDemo();
    if (mounted && ModalRoute.isCurrentOf(context) != false) widget.onStart();
    _openingCamera = false;
  }

  void _releaseDemo() {
    final video = _video;
    if (video == null) return;
    _playRequest++;
    _video = null;
    unawaited(video.dispose().catchError((Object _) {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _releaseDemo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movement = widget.movement;
    final (framing, cue) = switch (movement) {
      TrainingMovement.squat => (
        'Apóyalo en el piso. Deja visibles la cabeza y los pies.',
        'Baja la cadera y vuelve a subir',
      ),
      TrainingMovement.pushUp => (
        'Apóyalo en el piso, un poco de lado. Deja visibles las manos y los pies.',
        'Baja el pecho y vuelve a subir',
      ),
      TrainingMovement.crunch => (
        'Apóyalo en el piso, en diagonal. Deja visibles los hombros, la cadera y los pies.',
        'Eleva los hombros y baja con control',
      ),
      TrainingMovement.plank => (
        'Apóyalo en el piso, en diagonal. Deja visibles el torso y los pies.',
        'Alinea hombros, cadera y tobillos',
      ),
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final demoHeight = math.min(
              constraints.maxWidth - 24,
              constraints.maxHeight * .57,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    children: [
                      _ExerciseDemo(
                        movement: movement,
                        height: demoHeight.clamp(100.0, 460.0),
                        cue: cue,
                        video: _videoUnavailable ? null : _video,
                        unavailable: _videoUnavailable,
                        onToggle: _toggleDemo,
                      ),
                      const SizedBox(height: 18),
                      _CameraPlacement(movement: movement, detail: framing),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: _startCamera,
                        icon: const Icon(Icons.photo_camera_outlined, size: 25),
                        label: const Text(
                          'Activar cámara',
                          textAlign: TextAlign.center,
                        ),
                        style: FilledButton.styleFrom(
                          foregroundColor: AppColors.carbon,
                          backgroundColor: AppColors.volt,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'El video se analiza en tu teléfono.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.grayMain,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExerciseDemo extends StatelessWidget {
  const _ExerciseDemo({
    required this.movement,
    required this.height,
    required this.cue,
    required this.video,
    required this.unavailable,
    required this.onToggle,
  });

  final TrainingMovement movement;
  final double height;
  final String cue;
  final VideoPlayerController? video;
  final bool unavailable;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final controller = video;
    if (controller == null) return _buildFrame(null, null);
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) => _buildFrame(controller, value),
    );
  }

  Widget _buildFrame(
    VideoPlayerController? controller,
    VideoPlayerValue? value,
  ) {
    final ready =
        controller != null &&
        value != null &&
        value.isInitialized &&
        !value.hasError &&
        !value.size.isEmpty;
    final hasPoster = movement == TrainingMovement.squat;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: AppColors.carbon,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height,
              child: hasPoster
                  ? ColoredBox(
                      color: AppColors.panelSoft,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (ready)
                            FittedBox(
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              child: SizedBox.fromSize(
                                size: value.size,
                                child: VideoPlayer(controller),
                              ),
                            ),
                          // Keep the matching frame visible until playback advances.
                          if (!ready || value.position == Duration.zero)
                            Image.asset(
                              'assets/videos/sentadillas-frame.jpg',
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                            ),
                        ],
                      ),
                    )
                  : DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF0F0F0), Color(0xFFC6C6C6)],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                              ),
                              child: Image.asset(
                                'assets/icons/pose-${movement.id}.png',
                                width: 210,
                                height: height * .60,
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Video de demostración',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.carbon,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: ready
                  ? const EdgeInsets.fromLTRB(13, 6, 13, 7)
                  : const EdgeInsets.fromLTRB(13, 8, 13, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasPoster && (unavailable || value?.hasError == true)
                              ? 'Video no disponible'
                              : cue,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (ready)
                        IconButton(
                          onPressed: onToggle,
                          tooltip: value.isPlaying
                              ? 'Pausar demostración'
                              : 'Reproducir demostración',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 28,
                          ),
                          color: Colors.white,
                          icon: Icon(
                            value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 24,
                          ),
                        )
                      else
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.textGray,
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  if (ready)
                    SizedBox(
                      height: 3,
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: false,
                        padding: EdgeInsets.zero,
                        colors: const VideoProgressColors(
                          playedColor: AppColors.volt,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPlacement extends StatelessWidget {
  const _CameraPlacement({required this.movement, required this.detail});

  final TrainingMovement movement;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final standing = movement == TrainingMovement.squat;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.subtleBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: ExcludeSemantics(
                child: AspectRatio(
                  aspectRatio: 1.15,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(
                            painter: _FramingDiagram(standing: standing),
                          ),
                          if (!standing)
                            Positioned(
                              left: constraints.maxWidth * .39,
                              right: constraints.maxWidth * .04,
                              bottom: constraints.maxHeight * .19,
                              height: constraints.maxHeight * .38,
                              child: Image.asset(
                                'assets/icons/pose-${movement.id}.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coloca tu celular',
                    style: TextStyle(
                      color: AppColors.carbon,
                      fontSize: 19,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: AppColors.carbon,
                      fontSize: 15,
                      height: 1.28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FramingDiagram extends CustomPainter {
  const _FramingDiagram({required this.standing});

  final bool standing;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 104);
    final outline = Paint()
      ..color = AppColors.carbon
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final accent = Paint()
      ..color = AppColors.volt
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(2, 98), const Offset(118, 98), outline);
    canvas.save();
    canvas.translate(17, 83);
    canvas.rotate(-.24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, -13, 14, 26),
        const Radius.circular(2.5),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, -13, 14, 26),
        const Radius.circular(2.5),
      ),
      outline,
    );
    canvas.drawLine(const Offset(-2, -10), const Offset(2, -10), outline);
    canvas.restore();
    canvas.drawLine(const Offset(11, 85), const Offset(6, 98), outline);

    final frame = standing
        ? const Rect.fromLTRB(51, 8, 107, 91)
        : const Rect.fromLTRB(43, 41, 117, 91);
    for (final (corner, dx, dy) in [
      (frame.topLeft, 1, 1),
      (frame.topRight, -1, 1),
      (frame.bottomLeft, 1, -1),
      (frame.bottomRight, -1, -1),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx + dx * 8, corner.dy)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx, corner.dy + dy * 8),
        accent,
      );
    }
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(28 + i * 4, 91 - i * .9),
        Offset(30 + i * 4, 90.5 - i * .9),
        accent,
      );
    }
    if (standing) {
      final silhouette = Paint()..color = AppColors.carbon;
      canvas.drawOval(const Rect.fromLTWH(75, 12, 10, 12), silhouette);
      canvas.drawPath(
        Path()
          ..moveTo(83, 13)
          ..cubicTo(88, 12, 90, 17, 88, 22)
          ..quadraticBezierTo(88, 25, 90, 27)
          ..quadraticBezierTo(84, 26, 84, 21)
          ..close(),
        silhouette,
      );
      canvas.drawPath(
        Path()
          ..moveTo(77.5, 22)
          ..lineTo(82.5, 22)
          ..lineTo(83, 26)
          ..cubicTo(85, 28, 89, 27, 90, 32)
          ..lineTo(92, 44)
          ..lineTo(94, 54)
          ..quadraticBezierTo(93, 58, 90, 55)
          ..lineTo(87, 44)
          ..lineTo(86, 36)
          ..cubicTo(84, 42, 84, 47, 87, 52)
          ..cubicTo(89, 59, 86, 66, 87, 73)
          ..lineTo(88, 84)
          ..quadraticBezierTo(93, 87, 91, 89)
          ..lineTo(83, 89)
          ..lineTo(82, 74)
          ..lineTo(80, 58)
          ..lineTo(78, 74)
          ..lineTo(76.5, 89)
          ..lineTo(69, 89)
          ..quadraticBezierTo(67, 87, 72, 84)
          ..lineTo(73, 72)
          ..cubicTo(73, 64, 71, 58, 73, 52)
          ..cubicTo(76, 47, 76, 42, 74, 36)
          ..lineTo(73, 44)
          ..lineTo(70, 55)
          ..quadraticBezierTo(67, 58, 66, 54)
          ..lineTo(68, 44)
          ..lineTo(70, 32)
          ..cubicTo(71, 27, 75, 28, 77, 26)
          ..close(),
        silhouette,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FramingDiagram oldDelegate) =>
      oldDelegate.standing != standing;
}
