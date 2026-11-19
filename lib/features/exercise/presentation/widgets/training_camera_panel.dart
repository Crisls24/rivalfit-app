import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

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
                      child: RepaintBoundary(child: CameraPreview(camera)),
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
