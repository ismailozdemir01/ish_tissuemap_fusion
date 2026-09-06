import 'package:flutter_test/flutter_test.dart';
import 'package:ish_tissuemap_fusion/core/visual_inertial_fusion_engine.dart';
import 'package:ish_tissuemap_fusion/models/body_scan.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  const engine = VisualInertialFusionEngine();

  test('fuses valid inertial and visual observations', () {
    const inertial = ScanPose(
      timestampMicros: 1000,
      x: 0,
      y: 0,
      z: 0,
      qx: 0,
      qy: 0,
      qz: 0,
      qw: 1,
      quality: 0.75,
    );
    final visual = VisualPoseObservation(
      timestampMicros: 1100,
      position: Vector3(1, 0, 0),
      orientation: Quaternion.identity(),
      quality: 0.9,
      uncertaintyMeters: 0.1,
    );

    final fused = engine.fuse(inertial: inertial, visual: visual);
    expect(fused, isNotNull);
    expect(fused!.x, greaterThan(0));
    expect(fused.x, lessThanOrEqualTo(1));
    expect(fused.quality, greaterThan(0));
  });

  test('rejects missing or invalid visual observation instead of inventing pose', () {
    const inertial = ScanPose(
      timestampMicros: 1000,
      x: 0,
      y: 0,
      z: 0,
      qx: 0,
      qy: 0,
      qz: 0,
      qw: 1,
      quality: 0.75,
    );
    final visual = VisualPoseObservation(
      timestampMicros: 1100,
      position: Vector3(0, 0, 0),
      orientation: Quaternion.identity(),
      quality: 0,
      uncertaintyMeters: 1,
    );

    expect(engine.fuse(inertial: inertial, visual: visual), isNull);
  });
}
