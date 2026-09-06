import 'package:flutter_test/flutter_test.dart';

import 'package:ish_tissuemap_fusion/core/optical_registration_engine.dart';
import 'package:ish_tissuemap_fusion/core/pose_history.dart';
import 'package:ish_tissuemap_fusion/models/body_scan.dart';
import 'package:ish_tissuemap_fusion/models/optical_frame.dart';

void main() {
  test('registers a real frame against an interpolated pose', () {
    final history = PoseHistory(maxAgeMicros: 100000);
    history.add(const ScanPose(
      timestampMicros: 1000,
      x: 0,
      y: 0,
      z: 0,
      qx: 0,
      qy: 0,
      qz: 0,
      qw: 1,
      quality: 0.8,
    ));
    history.add(const ScanPose(
      timestampMicros: 3000,
      x: 2,
      y: 0,
      z: 0,
      qx: 0,
      qy: 0,
      qz: 0,
      qw: 1,
      quality: 0.9,
    ));

    const frame = OpticalFrame(
      path: '/tmp/frame.jpg',
      timestampMicros: 2000,
      width: 640,
      height: 480,
      format: 'jpeg',
      cameraId: 'back',
    );

    final result = const OpticalRegistrationEngine().register(frame, history);

    expect(result, isNotNull);
    expect(result!.pose.x, closeTo(1.0, 1e-9));
    expect(result.timestampInterpolated, isTrue);
    expect(result.usable, isTrue);
  });

  test('rejects frames without a sufficiently recent measured pose', () {
    final history = PoseHistory(maxAgeMicros: 1000);
    history.add(const ScanPose(
      timestampMicros: 1000,
      x: 0,
      y: 0,
      z: 0,
      qx: 0,
      qy: 0,
      qz: 0,
      qw: 1,
      quality: 0.8,
    ));

    const frame = OpticalFrame(
      path: '/tmp/frame.jpg',
      timestampMicros: 10000,
      width: 640,
      height: 480,
      format: 'jpeg',
      cameraId: 'back',
    );

    expect(const OpticalRegistrationEngine().register(frame, history), isNull);
  });
}
