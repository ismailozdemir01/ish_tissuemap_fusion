import 'package:camera/camera.dart' as camera_api;

import '../../models/optical_frame.dart';

class OpticalCameraService {
  camera_api.CameraController? _controller;
  camera_api.CameraDescription? _description;

  camera_api.CameraController? get controller => _controller;
  bool get initialized => _controller?.value.isInitialized == true;

  Future<List<camera_api.CameraDescription>> availableCameras() => camera_api.availableCameras();

  Future<void> initialize({camera_api.CameraDescription? camera, camera_api.ResolutionPreset preset = camera_api.ResolutionPreset.high}) async {
    final cameras = await camera_api.availableCameras();
    if (cameras.isEmpty && camera == null) throw StateError('CAMERA_UNAVAILABLE');
    final selected = camera ?? cameras.first;
    await _controller?.dispose();
    _description = selected;
    final controller = camera_api.CameraController(selected, preset, enableAudio: false);
    await controller.initialize();
    _controller = controller;
  }

  Future<OpticalFrame> capture() async {
    final controller = _controller;
    final description = _description;
    if (controller == null || description == null || !controller.value.isInitialized) {
      throw StateError('CAMERA_NOT_INITIALIZED');
    }
    final file = await controller.takePicture();
    return OpticalFrame(
      path: file.path,
      timestampMicros: DateTime.now().microsecondsSinceEpoch,
      width: controller.value.previewSize?.width.round() ?? 0,
      height: controller.value.previewSize?.height.round() ?? 0,
      format: 'image',
      cameraId: description.name,
    );
  }

  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    _description = null;
    await controller?.dispose();
  }
}
