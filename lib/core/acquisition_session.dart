import 'dart:async';

import '../models/imaging_pipeline.dart';
import 'sensor_capability.dart';

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
        // Subscribe before starting the sensor so synchronous first emissions
        // cannot be lost during startup.
        final subscription = sensor.samples.listen(
          _controller.add,
          onError: _controller.addError,
        );
        _subscriptions.add(subscription);
        try {
          await sensor.start();
        } catch (_) {
          await subscription.cancel();
          _subscriptions.remove(subscription);
          rethrow;
        }
      }

      for (final device in devices) {
        await device.connect();
        if (!device.connected) {
          throw StateError('ACQUISITION_DEVICE_NOT_CONNECTED:${device.deviceId}');
        }
        final subscription = device.acquire().listen(
          _controller.add,
          onError: _controller.addError,
        );
        _subscriptions.add(subscription);
      }
    } catch (_) {
      await stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!_running && _subscriptions.isEmpty) return;
    _running = false;
    for (final subscription in List<StreamSubscription<RawSignalSample>>.from(_subscriptions)) {
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
