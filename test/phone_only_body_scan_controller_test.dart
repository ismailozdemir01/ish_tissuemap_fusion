import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ish_tissuemap_fusion/core/acquisition_session.dart';
import 'package:ish_tissuemap_fusion/core/phone_only_body_scan_controller.dart';
import 'package:ish_tissuemap_fusion/core/sensor_capability.dart';
import 'package:ish_tissuemap_fusion/models/imaging_pipeline.dart';

class _FakeSensor implements PhoneSensor {
  _FakeSensor(this._events);
  final List<RawSignalSample> _events;
  final StreamController<RawSignalSample> _controller = StreamController.broadcast();

  @override
  final SensorCapability capability = const SensorCapability(id: 'test.accelerometer', name: 'Test Accelerometer', modality: SignalModality.inertial, availability: SensorAvailability.available, units: ['m/s²']);

  @override
  Stream<RawSignalSample> get samples => _controller.stream;

  @override
  Future<void> start() async {
    for (final event in _events) {
      _controller.add(event);
    }
  }

  @override
  Future<void> stop() async {}

  Future<void> dispose() => _controller.close();
}

void main() {
  test('records real sensor samples and stops cleanly', () async {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final sensor = _FakeSensor([
      RawSignalSample(sensorId: 'test.accelerometer', modality: SignalModality.inertial, timestampMicros: timestamp, values: const [0, 0, 9.80665], unit: 'm/s²', quality: 1),
    ]);
    final controller = PhoneOnlyBodyScanController(acquisition: AcquisitionSession(sensors: [sensor]));
    final received = <dynamic>[];
    final subscription = controller.samples.listen(received.add);
    await controller.start(initializeCamera: false);
    await Future<void>.delayed(Duration.zero);

    expect(controller.running, isTrue);
    expect(received.length, 1);
    expect(controller.coverage.sampleCount, 1);
    expect(controller.pose.quality, greaterThan(0));

    await controller.stop();
    expect(controller.running, isFalse);
    await subscription.cancel();
    await controller.dispose();
    await sensor.dispose();
  });

  test('does not fabricate RF samples when platform bridge is unavailable', () async {
    final sensor = _FakeSensor(const []);
    final controller = PhoneOnlyBodyScanController(acquisition: AcquisitionSession(sensors: [sensor]));
    await controller.start(initializeCamera: false);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(controller.rfMapper.baseline(), isNull);
    await controller.dispose();
    await sensor.dispose();
  });
}
