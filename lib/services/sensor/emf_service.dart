import 'package:sensors_plus/sensors_plus.dart';

class EMFService {
  double _currentMicroTesla = 50.0;
  final List<double> _history = [];

  void startListening(Function(double) onData) {
    magnetometerEvents.listen((MagnetometerEvent event) {
      // 3 Eksenin vektörel büyüklüğü (µT cinsinden)
      double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // Hareketli Ortalama Filtresi (Gerçek gürültü azaltma)
      _history.add(magnitude);
      if (_history.length > 20) _history.removeAt(0);

      double avg = _history.reduce((a, b) => a + b) / _history.length;
      _currentMicroTesla = avg;

      // Normalize: 50 µT referans al, sapmayı 0-1 arasına dönüştür
      double conductivityIndex =
          ((avg - 45).abs() / 15).clamp(0.0, 1.0);

      onData(conductivityIndex);
    });
  }

  double get currentValue => _currentMicroTesla;
}
