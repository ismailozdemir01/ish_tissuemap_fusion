import 'package:flutter_test/flutter_test.dart';

import 'package:ish_tissuemap_fusion/core/fusion_engine.dart';
import 'package:ish_tissuemap_fusion/core/imaging_orchestrator.dart';
import 'package:ish_tissuemap_fusion/core/reconstruction_engine.dart';
import 'package:ish_tissuemap_fusion/models/imaging_pipeline.dart';

void main() {
  RawSignalSample sample(SignalModality modality, String unit, int timestamp, double value) => RawSignalSample(
        sensorId: '$modality.sensor', modality: modality, timestampMicros: timestamp,
        values: [value], unit: unit, quality: 1.0,
      );

  test('fusion never averages heterogeneous physical units', () {
    final engine = FusionEngine();
    final result = engine.fuse([
      [sample(SignalModality.magnetic, 'µT', 1000, 40), sample(SignalModality.inertial, 'm/s²', 1001, 9.8)],
    ]);
    expect(result, isEmpty);
  });

  test('typed feature fusion preserves modality, unit and provenance', () {
    final engine = FusionEngine();
    final result = engine.fuseFeatures([
      [sample(SignalModality.magnetic, 'µT', 1000, 40), sample(SignalModality.inertial, 'm/s²', 1001, 9.8)],
    ]);
    expect(result, hasLength(1));
    expect(result.single.modalities, containsAll([SignalModality.magnetic, SignalModality.inertial]));
    expect(result.single.features.map((f) => f.unit), containsAll(['µT', 'm/s²']));
  });

  test('orchestrator does not claim an image without a validated reconstruction algorithm', () {
    final orchestrator = ImagingOrchestrator(reconstruction: ReconstructionEngine());
    final result = orchestrator.process([sample(SignalModality.magnetic, 'µT', 1000, 40)]);
    expect(result.state, PipelineState.unavailable);
    expect(result.reason, 'NO_VALIDATED_RECONSTRUCTION_ALGORITHM');
    expect(result.reconstructions[SignalModality.magnetic]?.validated, isFalse);
  });

  test('empty acquisition is explicitly unavailable', () {
    final result = ImagingOrchestrator().process(const []);
    expect(result.state, PipelineState.unavailable);
    expect(result.reason, 'NO_ACQUISITION_DATA');
  });
}
