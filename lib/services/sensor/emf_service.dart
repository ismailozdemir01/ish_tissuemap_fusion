import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Raw phone magnetometer telemetry. It is intentionally not converted into
/// tissue conductivity because that conversion is not clinically validated.
class EMFService {
  double _currentMicroTesla = 0;
  final List<double> _history = [];
  StreamSubscription<MagnetometerEvent>? _subscription;

  void startListening(void Function(double rawMicroTesla) onData) {
    _subscription?.cancel();
    _subscription = magnetometerEventStream().listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (!magnitude.isFinite) return;
      _history.add(magnitude);
      if (_history.length > 20) _history.removeAt(0);
      _currentMicroTesla = _history.reduce((a, b) => a + b) / _history.length;
      onData(_currentMicroTesla);
    });
  }

  double get currentValue => _currentMicroTesla;

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
