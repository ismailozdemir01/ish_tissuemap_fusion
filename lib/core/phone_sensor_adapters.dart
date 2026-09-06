import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../models/imaging_pipeline.dart';
import 'sensor_capability.dart';

abstract class _StreamPhoneSensor implements PhoneSensor {
  final StreamController<RawSignalSample> _controller = StreamController<RawSignalSample>.broadcast();
  StreamSubscription<dynamic>? _subscription;

  @override
  Stream<RawSignalSample> get samples => _controller.stream;

  void listenTo(Stream<dynamic> source, RawSignalSample Function(dynamic event) map) {
    _subscription?.cancel();
    _subscription = source.listen((event) => _controller.add(map(event)), onError: _controller.addError);
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}

class AccelerometerPhoneSensor extends _StreamPhoneSensor {
  @override
  final SensorCapability capability = const SensorCapability(
    id: 'phone.accelerometer', name: 'Accelerometer', modality: SignalModality.inertial,
    availability: SensorAvailability.available, units: ['m/s²'],
  );

  @override
  Future<void> start() async => listenTo(accelerometerEventStream(), (AccelerometerEvent e) => RawSignalSample(
    sensorId: capability.id, modality: capability.modality, timestampMicros: e.timestamp.microsecondsSinceEpoch,
    values: [e.x, e.y, e.z], unit: 'm/s²', quality: 1.0,
  ));
}

class GyroscopePhoneSensor extends _StreamPhoneSensor {
  @override
  final SensorCapability capability = const SensorCapability(
    id: 'phone.gyroscope', name: 'Gyroscope', modality: SignalModality.inertial,
    availability: SensorAvailability.available, units: ['rad/s'],
  );

  @override
  Future<void> start() async => listenTo(gyroscopeEventStream(), (GyroscopeEvent e) => RawSignalSample(
    sensorId: capability.id, modality: capability.modality, timestampMicros: e.timestamp.microsecondsSinceEpoch,
    values: [e.x, e.y, e.z], unit: 'rad/s', quality: 1.0,
  ));
}

class MagnetometerPhoneSensor extends _StreamPhoneSensor {
  @override
  final SensorCapability capability = const SensorCapability(
    id: 'phone.magnetometer', name: 'Magnetometer', modality: SignalModality.magnetic,
    availability: SensorAvailability.available, units: ['µT'],
  );

  @override
  Future<void> start() async => listenTo(magnetometerEventStream(), (MagnetometerEvent e) => RawSignalSample(
    sensorId: capability.id, modality: capability.modality, timestampMicros: e.timestamp.microsecondsSinceEpoch,
    values: [e.x, e.y, e.z], unit: 'µT', quality: 1.0,
  ));
}

class PhoneSensorRegistry {
  final List<PhoneSensor> sensors;
  PhoneSensorRegistry(this.sensors);

  factory PhoneSensorRegistry.defaults() => PhoneSensorRegistry([
    AccelerometerPhoneSensor(), GyroscopePhoneSensor(), MagnetometerPhoneSensor(),
  ]);
}
