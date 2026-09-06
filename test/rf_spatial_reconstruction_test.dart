import 'package:flutter_test/flutter_test.dart';

import 'package:ish_tissuemap_fusion/core/rf_field_reconstruction.dart';
import 'package:ish_tissuemap_fusion/core/rf_spatial_mapper.dart';
import 'package:ish_tissuemap_fusion/models/body_scan.dart';
import 'package:ish_tissuemap_fusion/models/rf_measurement.dart';

double _rssi(int i) => -50.0 - i.toDouble();

void main() {
  ScanPose pose(int i) => ScanPose(
        timestampMicros: i * 1000,
        x: i.toDouble() * 0.01,
        y: 0,
        z: 0,
        qx: 0,
        qy: 0,
        qz: 0,
        qw: 1,
        quality: 1,
      );

  RfMeasurement measurement(int i) => RfMeasurement(
        timestampMicros: i * 1000,
        accessLevel: RfAccessLevel.rssi,
        frequencyMHz: 5180,
        rssiDbm: _rssi(i),
        quality: 1,
      );

  test('mapper ignores unavailable RF observations', () {
    final mapper = RfSpatialMapper();
    mapper.add(pose: pose(0), measurement: const RfMeasurement(
      timestampMicros: 0,
      accessLevel: RfAccessLevel.unavailable,
      quality: 0,
      reason: 'RF_NATIVE_BRIDGE_NOT_IMPLEMENTED',
    ));
    expect(mapper.points, isEmpty);
  });

  test('mapper builds baseline and coverage from real-shaped observations', () {
    final mapper = RfSpatialMapper();
    for (var i = 0; i < 6; i++) {
      mapper.add(pose: pose(i), measurement: measurement(i));
    }
    expect(mapper.baseline(), isNotNull);
    expect(mapper.points.length, 6);
    expect(mapper.coverageLengthMeters(), closeTo(0.05, 1e-9));
  });

  test('RSSI reconstruction returns an RF field, not anatomical volume', () {
    final mapper = RfSpatialMapper();
    for (var i = 0; i < 6; i++) {
      mapper.add(pose: pose(i), measurement: measurement(i));
    }
    final result = const RfFieldReconstruction(gridSize: 3).reconstruct(mapper);
    expect(result.status, 'RF_FIELD_READY');
    expect(result.volumetric, isFalse);
    expect(result.voxels, isNotEmpty);
    expect(result.reason, 'RSSI_SPATIAL_FIELD_ONLY');
  });

  test('reconstruction refuses insufficient observability', () {
    final mapper = RfSpatialMapper();
    for (var i = 0; i < 4; i++) {
      mapper.add(pose: pose(i), measurement: measurement(i));
    }
    final result = const RfFieldReconstruction().reconstruct(mapper);
    expect(result.status, 'UNKNOWN');
    expect(result.voxels, isEmpty);
  });
}
