import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../domain/models/posture_readiness.dart';
import '../../domain/models/squat_observation.dart';
import '../../domain/models/training_observation.dart';
import '../../domain/models/training_session.dart';
import '../../domain/services/push_up_counter.dart';

enum TrainingCameraStatus {
  idle,
  loading,
  ready,
  denied,
  restricted,
  error,
  unsupported,
}

/// Android-only stream. At most one frame is processed at a time, without
/// recording files, audio or sending images over the network.
class TrainingCameraController extends ChangeNotifier {
  TrainingCameraController({
    this.onObservation,
    this.movement = TrainingMovement.squat,
  });

  final ValueChanged<TrainingObservation>? onObservation;
  final TrainingMovement movement;
  final _gate = PostureReadinessGate();
  final _pushUpGate = PushUpPoseGate();
  final _clock = Stopwatch()..start();
  CameraController? _camera;
  PoseDetector? _detector;
  Future<void> _operations = Future.value();
  Future<void>? _processing;
  bool _closed = false;
  bool _wanted = false;
  Timer? _watchdog;
  Duration _lastFrame = Duration.zero;
  Duration _lastResult = Duration.zero;
  TrainingCameraStatus _status = TrainingCameraStatus.idle;
  PostureReadiness _readiness = const PostureReadiness(
    false,
    false,
    'Colócate frente a la cámara con todo el cuerpo visible.',
  );
  String? _error;

  CameraController? get camera => _camera;
  TrainingCameraStatus get status => _status;
  PostureReadiness get readiness => _readiness;
  String? get error => _error;

  Future<void> activate() {
    if (_closed) return Future.value();
    _wanted = true;
    return _enqueue(_open);
  }

  Future<void> deactivate() {
    _wanted = false;
    return _enqueue(_release);
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    _operations = _operations.then((_) => operation()).catchError((Object e) {
      if (!_closed) {
        _status = TrainingCameraStatus.error;
        _error = 'No se pudo preparar la cámara. Inténtalo de nuevo.';
        _emit();
      }
    });
    return _operations;
  }

  void _emit() {
    if (!_closed) notifyListeners();
  }

  Future<void> _open() async {
    if (_closed || !_wanted || _camera != null) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _status = TrainingCameraStatus.unsupported;
      _emit();
      return;
    }
    _status = TrainingCameraStatus.loading;
    _error = null;
    _emit();
    CameraController? candidate;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('NoCamera', 'No camera');
      final description = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      candidate = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await candidate.initialize();
      await candidate.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (_closed || !_wanted) {
        await candidate.dispose();
        return;
      }
      _camera = candidate;
      _detector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.base,
        ),
      );
      _resetPoseGate();
      _lastResult = _clock.elapsed;
      await candidate.startImageStream(_onImage);
      _status = TrainingCameraStatus.ready;
      _watchdog = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (_clock.elapsed - _lastResult > const Duration(seconds: 1)) {
          _reportTrackingLoss(
            const PostureReadiness(
              false,
              false,
              'No vemos tu postura. Vuelve a colocarte frente a la cámara.',
            ),
          );
          _resetPoseGate();
        }
      });
      _emit();
    } on CameraException catch (e) {
      if (_camera == null) await candidate?.dispose();
      await _release();
      _status = switch (e.code) {
        'CameraAccessDenied' ||
        'CameraAccessDeniedWithoutPrompt' => TrainingCameraStatus.denied,
        'CameraAccessRestricted' => TrainingCameraStatus.restricted,
        _ => TrainingCameraStatus.error,
      };
      _error = _status == TrainingCameraStatus.denied
          ? 'Permite el acceso a la cámara para preparar tu entrenamiento.'
          : 'No se pudo abrir la cámara. Cierra otras apps que puedan estar usándola.';
      _emit();
    } catch (_) {
      if (_camera == null) await candidate?.dispose();
      await _release();
      _status = TrainingCameraStatus.error;
      _error =
          'No se pudo iniciar la detección de postura. Inténtalo de nuevo.';
      _emit();
    }
  }

  void _onImage(CameraImage image) {
    if (_closed ||
        !_wanted ||
        _processing != null ||
        _clock.elapsed - _lastFrame < const Duration(milliseconds: 150)) {
      return;
    }
    _lastFrame = _clock.elapsed;
    final timing = kProfileMode
        ? (TimelineTask()..start(
            movement == TrainingMovement.squat ? 'Squat pose' : 'Push-up pose',
          ))
        : null;
    _processing = _process(image).whenComplete(() {
      timing?.finish();
      _processing = null;
    });
  }

  Future<void> _process(CameraImage image) async {
    final controller = _camera;
    final detector = _detector;
    if (controller == null || detector == null) return;
    try {
      const orientations = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };
      final deviceRotation = orientations[controller.value.deviceOrientation]!;
      final description = controller.description;
      final degrees = description.lensDirection == CameraLensDirection.front
          ? (description.sensorOrientation + deviceRotation) % 360
          : (description.sensorOrientation - deviceRotation + 360) % 360;
      final rotation = InputImageRotationValue.fromRawValue(degrees);
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (rotation == null ||
          format == null ||
          format != InputImageFormat.nv21 ||
          image.planes.length != 1) {
        throw StateError('Unsupported camera image format');
      }
      final poses = await detector.processImage(
        InputImage.fromBytes(
          bytes: image.planes.first.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: format,
            bytesPerRow: image.planes.first.bytesPerRow,
          ),
        ),
      );
      if (_closed || !_wanted || controller != _camera) return;
      _lastResult = _clock.elapsed;
      if (poses.length != 1) {
        _resetPoseGate();
        _reportTrackingLoss(
          const PostureReadiness(
            false,
            false,
            'Colócate con el cuerpo completo dentro de la cámara.',
          ),
        );
        return;
      }
      final pose = poses.single;
      // Landmarks use the input image coordinate system. Normalize with its
      // rotated dimensions so edge checks match the portrait camera feed.
      final sideways =
          rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;
      final width = (sideways ? image.height : image.width).toDouble();
      final height = (sideways ? image.width : image.height).toDouble();
      List<BodyPoint> points(List<PoseLandmarkType> types) =>
          types.where(pose.landmarks.containsKey).map((type) {
            final p = pose.landmarks[type]!;
            return BodyPoint(p.x / width, p.y / height, p.likelihood);
          }).toList();
      final timestamp = _clock.elapsed;
      final aspectRatio = width / height;
      if (movement == TrainingMovement.pushUp) {
        final observation = _pushUpGate.evaluate(
          left: points([
            PoseLandmarkType.leftShoulder,
            PoseLandmarkType.leftElbow,
            PoseLandmarkType.leftWrist,
            PoseLandmarkType.leftHip,
            PoseLandmarkType.leftAnkle,
          ]),
          right: points([
            PoseLandmarkType.rightShoulder,
            PoseLandmarkType.rightElbow,
            PoseLandmarkType.rightWrist,
            PoseLandmarkType.rightHip,
            PoseLandmarkType.rightAnkle,
          ]),
          timestamp: timestamp,
          aspectRatio: aspectRatio,
        );
        onObservation?.call(observation);
        _update(observation.readiness);
        return;
      }
      final leftLeg = points([
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle,
      ]);
      final rightLeg = points([
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.rightAnkle,
      ]);
      final readiness = _gate.evaluate(
        leftLeg: leftLeg,
        rightLeg: rightLeg,
        shoulders: points([
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
        ]),
        timestamp: timestamp,
        aspectRatio: aspectRatio,
      );
      // Every processed frame reaches the counter, even when the instruction
      // has not changed. UI listeners remain limited to meaningful changes.
      onObservation?.call(
        SquatObservation(
          timestamp: timestamp,
          readiness: readiness,
          leftKneeAngle: jointAngle(leftLeg, aspectRatio),
          rightKneeAngle: jointAngle(rightLeg, aspectRatio),
          hipHeight: readiness.bodyVisible
              ? ((leftLeg[2].y - leftLeg[0].y) +
                        (rightLeg[2].y - rightLeg[0].y)) /
                    2
              : double.nan,
        ),
      );
      _update(readiness);
    } catch (_) {
      if (!_closed && _wanted) {
        _resetPoseGate();
        _update(
          const PostureReadiness(
            false,
            false,
            'No se pudo leer la postura. Reintenta la cámara.',
          ),
        );
        _status = TrainingCameraStatus.error;
        _error = 'La cámara no entregó imágenes compatibles con la detección.';
        _emit();
        unawaited(deactivate());
      }
    }
  }

  void _reportTrackingLoss(PostureReadiness readiness) {
    onObservation?.call(
      TrainingObservation(timestamp: _clock.elapsed, readiness: readiness),
    );
    _update(readiness);
  }

  void _update(PostureReadiness value) {
    if (_readiness.bodyVisible == value.bodyVisible &&
        _readiness.initialPostureReady == value.initialPostureReady &&
        _readiness.instruction == value.instruction) {
      return;
    }
    _readiness = value;
    _emit();
  }

  void _resetPoseGate() {
    _gate.reset();
    _pushUpGate.reset();
  }

  Future<void> _release() async {
    _watchdog?.cancel();
    _watchdog = null;
    _resetPoseGate();
    _readiness = const PostureReadiness(
      false,
      false,
      'Prepara la cámara para continuar.',
    );
    final camera = _camera;
    _camera = null;
    if (camera != null) {
      try {
        if (camera.value.isStreamingImages) await camera.stopImageStream();
      } finally {
        await _processing;
        await camera.dispose();
      }
    }
    final detector = _detector;
    _detector = null;
    await detector?.close();
    if (_status == TrainingCameraStatus.ready ||
        _status == TrainingCameraStatus.loading) {
      _status = TrainingCameraStatus.idle;
    }
    _emit();
  }

  @override
  void dispose() {
    _closed = true;
    _wanted = false;
    _clock.stop();
    _watchdog?.cancel();
    unawaited(_enqueue(_release));
    super.dispose();
  }
}
