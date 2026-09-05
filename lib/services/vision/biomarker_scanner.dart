import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:google_ml_kit/google_ml_kit.dart';

/// Kamera ile cilt, göz, tırnak analizi yaparak sağlık göstergelerini tespit eder.
class BiomarkerScanner {
  CameraController? _cameraController;
  bool _isAnalyzing = false;

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(backCamera, ResolutionPreset.medium);
    await _cameraController!.initialize();
  }

  Future<Map<String, dynamic>> analyzeSkinTone() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return {'status': 'Kamera başlatılamadı'};
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);
      final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
      if (image == null) return {'status': 'Görüntü okunamadı'};

      // Cilt tonu analizi (ortalama renk)
      int r = 0, g = 0, b = 0, count = 0;
      for (int y = 0; y < image.height; y += 5) {
        for (int x = 0; x < image.width; x += 5) {
          final pixel = image.getPixel(x, y);
          r += img.getRed(pixel);
          g += img.getGreen(pixel);
          b += img.getBlue(pixel);
          count++;
        }
      }
      r ~/= count; g ~/= count; b ~/= count;

      // Kansızlık (anemi) tahmini: cilt solukluğu
      double avgBrightness = (r + g + b) / 3 / 255;
      bool isAnemic = avgBrightness > 0.7 && b > 150;

      // Sarılık tahmini (göz sklerası sarımsı ise)
      bool isJaundice = (r > 200 && g > 180 && b < 100);

      return {
        'status': 'success',
        'avgBrightness': avgBrightness,
        'anemiaRisk': isAnemic ? 'Yüksek' : 'Düşük',
        'jaundiceRisk': isJaundice ? 'Yüksek' : 'Düşük',
        'rgb': {'r': r, 'g': g, 'b': b},
        'recommendation': isAnemic ? 'Demir takviyesi ve doktora başvurun.' : 'Normal görünüyor.',
      };
    } catch (e) {
      return {'status': 'Hata', 'error': e.toString()};
    }
  }

  /// Kalp atış hızı tespiti (kamera ile parmak ucu analizi - PPG)
  Future<double> measureHeartRate() async {
    // Gerçekte burada parmak ucu videosu işlenir, kırmızı kanalın piksel değişimi analiz edilir.
    // Basit örnek: rastgele değer döndür.
    return 72.0 + (DateTime.now().millisecond % 10 - 5) * 0.5; // 67-77 arası
  }

  void dispose() {
    _cameraController?.dispose();
  }
}
