import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

import '../../domain/models/posture_readiness.dart';
import '../controllers/training_camera_controller.dart';

class TrainingCameraPanel extends StatelessWidget {
  final TrainingCameraController controller;
  final int? countdown;
  final bool paused;
  const TrainingCameraPanel({
    super.key,
    required this.controller,
    required this.countdown,
    required this.paused,
  });

  Future<void> _openSettings(BuildContext context) async {
    try {
      await const MethodChannel('rivalfit/app_settings')
          .invokeMethod<void>('open');
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Abre Ajustes de Android → RivalFit → Permisos → Cámara.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final status = controller.status;
      final camera = controller.camera;
      final ready =
          !paused && status == TrainingCameraStatus.ready && camera != null;
      final loading = !paused && status == TrainingCameraStatus.loading;
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(
          color: AppColors.carbon,
          child: ready
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: CameraPreview(
                        camera,
                        child: ClipRect(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _PoseSkeletonPainter(
                                controller.poseFrame,
                                mirrored:
                                    camera.description.lensDirection ==
                                    CameraLensDirection.front,
                                color: controller.readiness.bodyVisible
                                    ? AppColors.volt
                                    : const Color(0xFFFFCF75),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (countdown case final seconds?)
                      Center(
                        child: Semantics(
                          liveRegion: true,
                          label: 'Inicio en $seconds',
                          excludeSemantics: true,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: AppColors.carbon.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$seconds',
                              style: const TextStyle(
                                color: AppColors.volt,
                                fontSize: 80,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (loading)
                          const CircularProgressIndicator(color: AppColors.volt)
                        else
                          Icon(
                            paused
                                ? Icons.pause_rounded
                                : Icons.videocam_off_outlined,
                            size: 42,
                            color: AppColors.volt,
                          ),
                        const SizedBox(height: 16),
                        Text(
                          paused
                              ? 'Serie en pausa'
                              : loading
                              ? 'Preparando cámara…'
                              : status == TrainingCameraStatus.unsupported
                              ? 'El entrenamiento con cámara está disponible en Android.'
                              : controller.error ?? 'La cámara está apagada.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                        if (!paused &&
                            (status == TrainingCameraStatus.denied ||
                                status == TrainingCameraStatus.restricted))
                          TextButton(
                            onPressed: () => _openSettings(context),
                            child: const Text(
                              'Abrir ajustes',
                              style: TextStyle(color: AppColors.volt),
                            ),
                          ),
                        if (!paused &&
                            (status == TrainingCameraStatus.error ||
                                status == TrainingCameraStatus.denied))
                          TextButton(
                            onPressed: controller.activate,
                            child: const Text(
                              'Reintentar cámara',
                              style: TextStyle(color: AppColors.volt),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    },
  );
}

typedef _Joint = PoseLandmarkType;

class _PoseSkeletonPainter extends CustomPainter {
  _PoseSkeletonPainter(
    this.frame, {
    required this.mirrored,
    required this.color,
  }) : super(repaint: frame);

  final ValueListenable<Map<PoseLandmarkType, BodyPoint>> frame;
  final bool mirrored;
  final Color color;

  static const _chains = [
    [
      _Joint.leftWrist,
      _Joint.leftElbow,
      _Joint.leftShoulder,
      _Joint.rightShoulder,
      _Joint.rightElbow,
      _Joint.rightWrist,
    ],
    [
      _Joint.leftShoulder,
      _Joint.leftHip,
      _Joint.leftKnee,
      _Joint.leftAnkle,
      _Joint.leftFootIndex,
    ],
    [
      _Joint.rightShoulder,
      _Joint.rightHip,
      _Joint.rightKnee,
      _Joint.rightAnkle,
      _Joint.rightFootIndex,
    ],
    [_Joint.leftHip, _Joint.rightHip],
    [_Joint.leftEar, _Joint.nose, _Joint.rightEar],
  ];
  static final _joints = _chains.expand((chain) => chain).toSet();

  @override
  void paint(Canvas canvas, Size size) {
    final points = <_Joint, Offset>{};
    for (final joint in _joints) {
      final point = frame.value[joint];
      if (point != null &&
          point.confidence >= .55 &&
          point.x >= 0 &&
          point.x <= 1 &&
          point.y >= 0 &&
          point.y <= 1) {
        points[joint] = Offset(
          (mirrored ? 1 - point.x : point.x) * size.width,
          point.y * size.height,
        );
      }
    }
    final outline = Paint()
      ..color = AppColors.carbon
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final chain in _chains) {
      for (var i = 1; i < chain.length; i++) {
        final a = points[chain[i - 1]];
        final b = points[chain[i]];
        if (a == null || b == null) continue;
        canvas.drawLine(a, b, outline);
        canvas.drawLine(a, b, stroke);
      }
    }
    for (final point in points.values) {
      canvas.drawCircle(point, 4.25, outline);
      canvas.drawCircle(point, 2.75, stroke);
    }
  }

  @override
  bool shouldRepaint(_PoseSkeletonPainter old) =>
      old.frame != frame || old.mirrored != mirrored || old.color != color;
}
