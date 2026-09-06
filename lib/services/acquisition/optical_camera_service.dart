import 'package:camera/camera.dart';

import '../../models/optical_frame.dart';

class OpticalCameraService {
  CameraController? _controller;
  CameraDescription? _description;

  CameraController? get controller => _controller;
  bool get initialized => _controller?.value.isInitialized == true;

  Future<List<CameraDescription>> availableCameras() => availableCameras();

  Future<void> initialize({CameraDescription? camera, ResolutionPreset preset = ResolutionPreset.high}) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty && camera == null) {
      throw StateError('CAMERA_UNAVAILABLE');
    }
    final selected = camera ?? cameras.first;
    await _controller?.dispose();
    _description = selected;
    final controller = CameraController(selected, preset, enableAudio: false);
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
