import 'package:flutter_test/flutter_test.dart';

import '../lib/core/common_coordinate_fusion_engine.dart';
import '../lib/core/visual_motion_estimator.dart';
import '../lib/models/body_scan.dart';
import '../lib/models/rf_measurement.dart';

void main() {
  test('visual pixel motion never becomes metric translation', () {
    final engine = CommonCoordinateFusionEngine();
    final accepted = engine.addVisualMotion(const VisualMotionObservation(
      timestampMicros: 1000,
      dxPixels: 20,
      dyPixels: -5,
      scale: 1,
      quality: 1,
      uncertaintyPixels: 1,
      matchCount: 20,
    ));

    expect(accepted, isTrue);
    expect(engine.state.metricPose, isNull);
    expect(engine.state.opticalDxPixels, 20);
    expect(engine.state.provenance, 'NON_METRIC_OPTICAL_ONLY');
  });

  test('measured pose anchors RF in the same coordinate system', () {
    final engine = CommonCoordinateFusionEngine();
    final pose = const ScanPose(
      timestampMicros: 1000,
      x: 0.2,
      y: 0.3,
      z: 0.4,
      qx: 0,
      qy: 0,
      qz: 0,
      qw: 1,
      quality: 0.9,
    );
    expect(engine.addMeasuredPose(pose), isTrue);
    final accepted = engine.addRfMeasurement(const RfMeasurement(
      timestampMicros: 1000,
      accessLevel: RfAccessLevel.rssi,
      frequencyMHz: 2412,
      channel: 1,
      rssiDbm: -48,
      txLinkMbps: 100,
      rxLinkMbps: 100,
      channelWidthMHz: 20,
      quality: 0.9,
      reason: 'TEST_MEASURED_RF',
    ));

    expect(accepted, isTrue);
    expect(engine.state.rfObservationCount, 1);
    expect(engine.state.metricPose?.x, 0.2);
    expect(engine.state.provenance, 'MEASURED_IMU_POSE_PLUS_RF');
  });

  test('RF without a measured pose is rejected rather than placed arbitrarily', () {
    final engine = CommonCoordinateFusionEngine();
    final accepted = engine.addRfMeasurement(const RfMeasurement(
      timestampMicros: 1000,
      accessLevel: RfAccessLevel.rssi,
      frequencyMHz: 2412,
      channel: 1,
      rssiDbm: -50,
      txLinkMbps: 50,
      rxLinkMbps: 50,
      channelWidthMHz: 20,
      quality: 1,
      reason: 'TEST_NO_POSE',
    ));

    expect(accepted, isFalse);
    expect(engine.state.rfObservationCount, 0);
  });
}
