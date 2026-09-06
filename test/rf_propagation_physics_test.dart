import 'package:flutter_test/flutter_test.dart';

import 'package:ish_tissuemap_fusion/core/rf_propagation_physics.dart';

void main() {
  test('wavelength is frequency dependent', () {
    final low = RfPropagationPhysics.wavelengthMeters(2400);
    final high = RfPropagationPhysics.wavelengthMeters(5200);
    expect(low, greaterThan(high));
    expect(low, closeTo(0.1249135, 1e-5));
  });

  test('free-space path loss increases with distance', () {
    final near = RfPropagationPhysics.freeSpacePathLossDb(
      frequencyMHz: 2400,
      distanceMeters: 1,
    );
    final far = RfPropagationPhysics.freeSpacePathLossDb(
      frequencyMHz: 2400,
      distanceMeters: 2,
    );
    expect(far, greaterThan(near));
    expect(far - near, closeTo(6.0206, 1e-3));
  });

  test('path length uses real three-dimensional geometry', () {
    expect(
      RfPropagationPhysics.pathLengthMeters(
        source: [0, 0, 0],
        target: [1, 2, 2],
      ),
      closeTo(3, 1e-12),
    );
  });
}
