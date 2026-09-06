import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ish_tissuemap_fusion/core/acquisition_session.dart';
import 'package:ish_tissuemap_fusion/core/sensor_capability.dart';
import 'package:ish_tissuemap_fusion/models/imaging_pipeline.dart';

class FakePhoneSensor implements PhoneSensor {
  final StreamController<RawSignalSample> controller = StreamController<RawSignalSample>.broadcast();
  bool started = false;

  @override
  final capability = const SensorCapability(
    id: 'test.sensor',
    name: 'Test Sensor',
    modality: SignalModality.external,
    availability: SensorAvailability.available,
  );

  @override
  Stream<RawSignalSample> get samples => controller.stream;

  @override
  Future<void> start() async => started = true;

  @override
  Future<void> stop() async => started = false;

  Future<void> dispose() => controller.close();
}

class FailingDevice implements AcquisitionDevice {
  @override
  String get deviceId => 'failing-device';
  @override
  String get name => 'Failing device';
  @override
  Set<SignalModality> get modalities => {SignalModality.external};
  @override
  bool connected = false;
  @override
  Future<void> connect() async => connected = false;
  @override
  Future<void> disconnect() async => connected = false;
  @override
  Stream<RawSignalSample> acquire() => const Stream.empty();
}

void main() {
  test('acquisition session forwards real sensor samples and stops cleanly', () async {
    final sensor = FakePhoneSensor();
    final session = AcquisitionSession(sensors: [sensor]);
    final received = <RawSignalSample>[];
    final subscription = session.samples.listen(received.add);

    await session.start();
    expect(session.running, isTrue);
    sensor.controller.add(const RawSignalSample(
      sensorId: 'test.sensor',
      modality: SignalModality.external,
      timestampMicros: 1,
      values: [42],
      unit: 'unit',
      quality: 1,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(received, hasLength(1));

    await session.stop();
    expect(session.running, isFalse);
    expect(sensor.started, isFalse);
    await subscription.cancel();
    await session.dispose();
    await sensor.dispose();
  });

  test('device connection failure leaves session stopped', () async {
    final session = AcquisitionSession(devices: [FailingDevice()]);
    expect(() => session.start(), throwsA(isA<StateError>()));
    await Future<void>.delayed(Duration.zero);
    expect(session.running, isFalse);
    await session.dispose();
  });
}
