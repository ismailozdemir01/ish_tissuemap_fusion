import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../../core/sensor_capability.dart';
import '../../models/imaging_pipeline.dart';

abstract class _SensorsPlusPhoneSensor implements PhoneSensor {
  final StreamController<RawSignalSample> _controller = StreamController<RawSignalSample>.broadcast();
  StreamSubscription<dynamic>? _subscription;
  bool _started = false;

  @override
  Stream<RawSignalSample> get samples => _controller.stream;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _subscription = createStream().listen((event) {
        final sample = mapEvent(event);
        if (sample != null && !_controller.isClosed) _controller.add(sample);
      }, onError: _controller.addError);
    } catch (error, stack) {
      _started = false;
      if (!_controller.isClosed) _controller.addError(error, stack);
      rethrow;
    }
  }

  Stream<dynamic> createStream();
  RawSignalSample? mapEvent(dynamic event);

  @override
  Future<void> stop() async {
    _started = false;
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}

class PhoneMagnetometerSensor extends _SensorsPlusPhoneSensor {
  @override
  SensorCapability get capability => const SensorCapability(
        id: 'phone.magnetometer',
        name: 'Phone Magnetometer',
        modality: SignalModality.magnetic,
        availability: SensorAvailability.available,
        units: ['uT'],
      );

  @override
  Stream<dynamic> createStream() => magnetometerEventStream();

  @override
  RawSignalSample? mapEvent(dynamic event) {
    final e = event as MagnetometerEvent;
    final values = <double>[e.x, e.y, e.z];
    if (values.any((v) => !v.isFinite)) return null;
    return RawSignalSample(
      sensorId: capability.id,
      modality: capability.modality,
      timestampMicros: DateTime.now().microsecondsSinceEpoch,
      values: List.unmodifiable(values),
      unit: 'uT',
      quality: 1.0,
    );
  }
}

class PhoneAccelerometerSensor extends _SensorsPlusPhoneSensor {
  @override
  SensorCapability get capability => const SensorCapability(
        id: 'phone.accelerometer',
        name: 'Phone Accelerometer',
        modality: SignalModality.inertial,
        availability: SensorAvailability.available,
        units: ['m/s^2'],
      );

  @override
  Stream<dynamic> createStream() => accelerometerEventStream();

  @override
  RawSignalSample? mapEvent(dynamic event) {
    final e = event as AccelerometerEvent;
    final values = <double>[e.x, e.y, e.z];
    if (values.any((v) => !v.isFinite)) return null;
    return RawSignalSample(
      sensorId: capability.id,
      modality: capability.modality,
      timestampMicros: DateTime.now().microsecondsSinceEpoch,
      values: List.unmodifiable(values),
      unit: 'm/s^2',
      quality: 1.0,
    );
  }
}

class PhoneGyroscopeSensor extends _SensorsPlusPhoneSensor {
  @override
  SensorCapability get capability => const SensorCapability(
        id: 'phone.gyroscope',
        name: 'Phone Gyroscope',
        modality: SignalModality.inertial,
        availability: SensorAvailability.available,
        units: ['rad/s'],
      );

  @override
  Stream<dynamic> createStream() => gyroscopeEventStream();

  @override
  RawSignalSample? mapEvent(dynamic event) {
    final e = event as GyroscopeEvent;
    final values = <double>[e.x, e.y, e.z];
    if (values.any((v) => !v.isFinite)) return null;
    return RawSignalSample(
      sensorId: capability.id,
      modality: capability.modality,
      timestampMicros: DateTime.now().microsecondsSinceEpoch,
      values: List.unmodifiable(values),
      unit: 'rad/s',
      quality: 1.0,
    );
  }
}

class PhoneSensorRegistry {
  final List<PhoneSensor> sensors;

  PhoneSensorRegistry({List<PhoneSensor>? sensors})
      : sensors = List.unmodifiable(sensors ?? <PhoneSensor>[
          PhoneMagnetometerSensor(),
          PhoneAccelerometerSensor(),
          PhoneGyroscopeSensor(),
        ]);

  Future<void> startAll() async {
    for (final sensor in sensors) {
      await sensor.start();
    }
  }

  Future<void> stopAll() async {
    for (final sensor in sensors) {
      await sensor.stop();
    }
  }

  Stream<RawSignalSample> get samples => StreamGroupMerge.merge(sensors.map((s) => s.samples));
}

/// Minimal stream merge without adding another dependency.
class StreamGroupMerge {
  static Stream<T> merge<T>(Iterable<Stream<T>> streams) {
    final controller = StreamController<T>.broadcast();
    final subscriptions = <StreamSubscription<T>>[];
    controller.onListen = () {
      for (final stream in streams) {
        subscriptions.add(stream.listen(controller.add, onError: controller.addError));
      }
    };
    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
    return controller.stream;
  }
}
