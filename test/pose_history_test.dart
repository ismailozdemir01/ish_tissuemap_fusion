import 'package:flutter_test/flutter_test.dart';
import 'package:ish_tissuemap_fusion/core/pose_history.dart';
import 'package:ish_tissuemap_fusion/models/body_scan.dart';

ScanPose pose(int timestamp, double x, double quality) => ScanPose(
      timestampMicros: timestamp,
      x: x,
      y: 0,
      z: 0,
      qx: 0,
      qy: 0,
      qz: 0,
      qw: 1,
      quality: quality,
    );

void main() {
  test('nearest returns the temporally closest valid pose', () {
    final history = PoseHistory();
    history.add(pose(1000, 1, 0.8));
    history.add(pose(2000, 2, 0.8));
    history.add(pose(3000, 3, 0.8));

    expect(history.nearest(2400)?.x, 2);
  });

  test('interpolate creates a timestamp-aligned pose between samples', () {
    final history = PoseHistory();
    history.add(pose(1000, 1, 0.8));
    history.add(pose(3000, 3, 0.7));

    final aligned = history.interpolate(2000);
    expect(aligned, isNotNull);
    expect(aligned!.timestampMicros, 2000);
    expect(aligned.x, closeTo(2, 1e-9));
    expect(aligned.quality, closeTo(0.7, 1e-9));
  });

  test('old poses are evicted by age', () {
    final history = PoseHistory(maxAgeMicros: 1000);
    history.add(pose(1000, 1, 0.8));
    history.add(pose(2501, 2, 0.8));

    expect(history.poses, hasLength(1));
    expect(history.poses.single.timestampMicros, 2501);
  });
}
