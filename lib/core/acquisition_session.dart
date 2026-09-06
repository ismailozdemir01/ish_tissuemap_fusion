import 'dart:async';

import '../models/imaging_pipeline.dart';
import '../core/sensor_capability.dart';

class AcquisitionSession {
  final List<PhoneSensor> sensors;
  final List<AcquisitionDevice> devices;
  final StreamController<RawSignalSample> _controller = StreamController<RawSignalSample>.broadcast();
  final List<StreamSubscription<RawSignalSample>> _subscriptions = [];
  bool _running = false;

  AcquisitionSession({this.sensors = const [], this.devices = const []});

  bool get running => _running;
  Stream<RawSignalSample> get samples => _controller.stream;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    try {
      for (final sensor in sensors) {
        await sensor.start();
        _subscriptions.add(sensor.samples.listen(_controller.add, onError: _controller.addError));
      }
      for (final device in devices) {
        await device.connect();
        if (!device.connected) {
          throw StateError('ACQUISITION_DEVICE_NOT_CONNECTED:${device.deviceId}');
        }
        _subscriptions.add(device.acquire().listen(_controller.add, onError: _controller.addError));
      }
    } catch (_) {
      await stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!_running && _subscriptions.isEmpty) return;
    _running = false;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    for (final sensor in sensors) {
      await sensor.stop();
    }
    for (final device in devices) {
      if (device.connected) await device.disconnect();
    }
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
