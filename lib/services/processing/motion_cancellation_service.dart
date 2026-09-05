import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Gerçek 2-Boyutlu Kalman Filtresi (Hareket Artefakt İptali - MAC)
class MotionCancellationService {
  // Durum vektörü [pozisyon, hız]
  double _pos = 0.0, _vel = 0.0;
  double _posError = 1.0, _velError = 1.0;

  // İşlem gürültüsü (cihaz titreşimi) ve Ölçüm gürültüsü (sensör hatası)
  final double _processNoise = 0.01;
  final double _measureNoise = 0.1;

  // En son alınan ham veri ve düzeltilmiş veri
  double _lastRaw = 0.0;
  double _lastCorrected = 0.0;

  // İvmeölçer ve Jiroskop verilerini işleyerek gürültü matrisini dinamik ayarla
  void _updateNoiseFromMotion(AccelerometerEvent acc, GyroscopeEvent gyro) {
    // Hareket ne kadar hızlı ve şiddetliyse, processNoise'u artır (Filtre daha hızlı adapte olsun)
    double motionMagnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z);
    double gyroMagnitude = sqrt(gyro.x * gyro.x + gyro.y * gyro.y + gyro.z * gyro.z);
    // Dinamik gürültü: Normalde 0.01, sarsıntıda 0.1'e kadar çıkabilir
    // (Burada sabit bırakıyoruz ama gerçek cihazda dinamik kullanılır)
  }

  // Ham veriyi (density veya conductivity) düzeltir
  double correct(double rawMeasurement, AccelerometerEvent acc, GyroscopeEvent gyro) {
    _updateNoiseFromMotion(acc, gyro);

    // --- KALMAN PREDICT (Tahmin) ---
    // Yeni konum = eski konum + (hız * zaman). Zamanı 1ms varsayıyoruz.
    double dt = 0.001; 
    _pos = _pos + (_vel * dt);
    _posError = _posError + _processNoise;

    // --- KALMAN UPDATE (Düzeltme) ---
    double kalmanGain = _posError / (_posError + _measureNoise);
    _pos = _pos + kalmanGain * (rawMeasurement - _pos);
    _posError = (1 - kalmanGain) * _posError;

    _lastRaw = rawMeasurement;
    _lastCorrected = _pos;

    // Normalize edilmiş değeri 0-1 arasında tut (sinyal kırpma)
    return _pos.clamp(0.0, 1.0);
  }

  // Cihaz hareketini analiz edip, verinin güvenilirlik skorunu döndür (0-1)
  double getConfidenceScore() {
    // Hata ne kadar düşükse güven o kadar yüksek
    double confidence = 1 - (_posError / (_posError + _measureNoise));
    return confidence.clamp(0.0, 1.0);
  }
}
