import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math.dart' as vm;

class ARGuidanceService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;

  // Cihazın yönü (dokuyu nereye koyacağımızı bilmek için)
  double _yaw = 0.0; 

  ARGuidanceService() {
    // Gerçek Jiroskop ile yön takibi
    gyroscopeEvents.listen((GyroscopeEvent event) {
      _yaw += event.z * 0.01; // Basit entegrasyon (gerçekte kuvaterniyon kullanılır)
    });
  }

  // Kamera başlatma
  Future<void> initCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isEmpty) return;
    // Arka kamera
    CameraDescription? backCam = _cameras!.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );
    _controller = CameraController(backCam, ResolutionPreset.medium);
    await _controller?.initialize();
    _isReady = true;
  }

  bool get isReady => _isReady;
  CameraController? get controller => _controller;

  // Cihazın eğimine göre vücut üzerindeki tahmini konumu hesapla (x, y 0-1 normalize)
  vm.Vector2 estimatePositionOnBody() {
    // Yaw değerini +-1 arası normalize edip, vücut sol-sağ hareketine çevir
    double x = ((_yaw / 3.14) + 1) / 2; 
    // Pitch ve roll eklenebilir (kısaca ekliyoruz)
    return vm.Vector2(x.clamp(0.0, 1.0), 0.5); // Basit varsayım
  }

  // Görüntü üzerinde cilt tonu analizi (Basit örnek)
  Future<double> analyzeSkinTone() async {
    if (_controller == null || !_controller!.value.isInitialized) return 0.5;
    try {
      final img = await _controller!.takePicture();
      final imageFile = File(img.path);
      // Burada gerçek piksel analizi yapılır (ortalama renk değeri vs)
      // Dönüş: 0.0 (açık ten) - 1.0 (koyu ten)
      return 0.6; // Mock değer, gerçek uygulamada image paketiyle işlenir
    } catch (e) {
      return 0.5;
    }
  }

  void dispose() {
    _controller?.dispose();
  }
}
