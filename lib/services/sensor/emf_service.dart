import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class EMFService {
  double _currentMicroTesla = 50.0;
  final List<double> _history = [];

  void startListening(Function(double) onData) {
    magnetometerEvents.listen((MagnetometerEvent event) {
      double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      _history.add(magnitude);
      if (_history.length > 20) _history.removeAt(0);

      double avg = _history.reduce((a, b) => a + b) / _history.length;
      _currentMicroTesla = avg;

      double conductivityIndex = ((avg - 45).abs() / 15).clamp(0.0, 1.0);
      onData(conductivityIndex);
    });
  }

  double get currentValue => _currentMicroTesla;
}
