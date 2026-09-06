import 'package:flutter_test/flutter_test.dart';

import 'package:ish_tissuemap_fusion/core/rf_physical_feature_extractor.dart';
import 'package:ish_tissuemap_fusion/models/rf_measurement.dart';

void main() {
  const extractor = RfPhysicalFeatureExtractor(minimumQuality: 0.2);

  RfMeasurement m(int t, double rssi, {double frequency = 2412}) => RfMeasurement(
        timestampMicros: t,
        accessLevel: RfAccessLevel.rssi,
        frequencyMHz: frequency,
        rssiDbm: rssi,
        quality: 0.9,
      );

  test('derives baseline delta statistics and temporal slope from observations', () {
    final features = extractor.extract([
      m(0, -50),
      m(1000000, -52),
      m(2000000, -54),
    ]);

    expect(features, hasLength(1));
    expect(features.single.baselineRssiDbm, -50);
    expect(features.single.currentRssiDbm, -54);
    expect(features.single.deltaRssiDb, -4);
    expect(features.single.meanRssiDbm, -52);
    expect(features.single.temporalSlopeDbPerSecond, closeTo(-2, 1e-9));
  });

  test('keeps frequencies separate', () {
    final features = extractor.extract([
      m(0, -50, frequency: 2412),
      m(1000000, -51, frequency: 2412),
      m(0, -60, frequency: 5180),
      m(1000000, -62, frequency: 5180),
    ]);

    expect(features.map((f) => f.frequencyMHz).toSet(), {2412, 5180});
  });

  test('does not fabricate a feature from unavailable RF', () {
    final features = extractor.extract([
      const RfMeasurement(
        timestampMicros: 1,
        accessLevel: RfAccessLevel.unavailable,
        quality: 0,
        reason: 'RF_UNAVAILABLE',
      ),
    ]);

    expect(features, isEmpty);
  });
}
