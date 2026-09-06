import 'dart:io';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Camera acquisition and optical statistics only. Clinical biomarker
/// classification requires an externally validated model and is not inferred here.
class BiomarkerScanner {
  CameraController? _cameraController;

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final backCamera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
    _cameraController = CameraController(backCamera, ResolutionPreset.medium);
    await _cameraController!.initialize();
  }

  Future<Map<String, dynamic>> analyzeSkinTone() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return {'status': 'CAMERA_UNAVAILABLE'};
    try {
      final photo = await controller.takePicture();
      final image = img.decodeImage(await File(photo.path).readAsBytes());
      if (image == null) return {'status': 'IMAGE_UNAVAILABLE'};
      var r = 0.0;
      var g = 0.0;
      var b = 0.0;
      var count = 0;
      for (var y = 0; y < image.height; y += 5) {
        for (var x = 0; x < image.width; x += 5) {
          final pixel = image.getPixel(x, y);
          r += pixel.r.toDouble();
          g += pixel.g.toDouble();
          b += pixel.b.toDouble();
          count++;
        }
      }
      if (count == 0) return {'status': 'NO_OPTICAL_SAMPLES'};
      return {
        'status': 'OPTICAL_STATISTICS_ONLY',
        'meanRgb': {'r': r / count, 'g': g / count, 'b': b / count},
        'clinicalInterpretation': 'UNKNOWN_VALIDATED_MODEL_REQUIRED',
      };
    } catch (e) {
      return {'status': 'OPTICAL_ERROR', 'error': e.toString()};
    }
  }

  Future<double?> measureHeartRate() async => null;

  void dispose() {
    _cameraController?.dispose();
  }
}
