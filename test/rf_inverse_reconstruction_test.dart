import 'package:flutter_test/flutter_test.dart';

import 'package:ish_tissuemap_fusion/core/rf_inverse_reconstruction.dart';
import 'package:ish_tissuemap_fusion/core/rf_spatial_mapper.dart';
import 'package:ish_tissuemap_fusion/models/measurement_status.dart';

void main() {
  test('insufficient RF observations remain UNKNOWN', () {
    const engine = RfInverseReconstruction();
    final result = engine.reconstruct(const []);
    expect(result.status, MeasurementStatus.unknown);
    expect(result.anatomical, isFalse);
    expect(result.voxels, isEmpty);
  });

  test('real spatial RF field reconstruction never claims anatomy', () {
    const engine = RfInverseReconstruction(gridResolution: 3);
    final points = List.generate(
      5,
      (i) => RfSpatialPoint(
        x: i.toDouble(),
        y: 0,
        z: 0,
        rssiDbm: -50 - i,
        frequencyMHz: 2412,
        quality: 0.9,
        uncertaintyDb: 1,
      ),
    );
    final result = engine.reconstruct(points);
    expect(result.voxels, isNotEmpty);
    expect(result.anatomical, isFalse);
    expect(result.status, MeasurementStatus.unknown);
  });
}
