import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ish_tissuemap_fusion/core/acquisition_protocol.dart';
import 'package:ish_tissuemap_fusion/models/imaging_pipeline.dart';

void main() {
  const codec = AcquisitionFrameCodec();
  const sample = RawSignalSample(
    sensorId: 'phone.magnetometer', modality: SignalModality.magnetic,
    timestampMicros: 123456, values: [12.5, -3.0, 44.0], unit: 'µT', quality: 0.95,
  );

  test('acquisition frames round-trip with integrity metadata', () {
    final decoded = codec.decode(codec.encode([sample]));
    expect(decoded, hasLength(1));
    expect(decoded.single.sensorId, sample.sensorId);
    expect(decoded.single.modality, sample.modality);
    expect(decoded.single.values, sample.values);
    expect(decoded.single.unit, sample.unit);
  });

  test('tampered acquisition frame is rejected', () {
    final frame = codec.encode([sample]);
    frame[frame.length - 1] ^= 0x01;
    expect(() => codec.decode(Uint8List.fromList(frame)), throwsA(isA<AcquisitionProtocolException>()));
  });

  test('truncated acquisition frame is rejected', () {
    expect(() => codec.decode(Uint8List(4)), throwsA(isA<AcquisitionProtocolException>()));
  });
}
