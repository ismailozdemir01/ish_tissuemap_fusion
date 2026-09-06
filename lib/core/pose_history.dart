import 'dart:math' as math;

import '../models/body_scan.dart';

/// Timestamp-indexed pose history used to align asynchronous RF/camera samples
/// with the nearest measured phone pose.
///
/// This is an alignment primitive, not a claim of absolute localization.
class PoseHistory {
  PoseHistory({this.maxSamples = 512, this.maxAgeMicros = 500000})
      : assert(maxSamples > 0),
        assert(maxAgeMicros > 0);

  final int maxSamples;
  final int maxAgeMicros;
  final List<ScanPose> _poses = <ScanPose>[];

  List<ScanPose> get poses => List.unmodifiable(_poses);

  void clear() => _poses.clear();

  void add(ScanPose pose) {
    if (pose.timestampMicros < 0 || !pose.quality.isFinite) return;
    if (_poses.isNotEmpty && pose.timestampMicros < _poses.last.timestampMicros) {
      _poses.add(pose);
      _poses.sort((a, b) => a.timestampMicros.compareTo(b.timestampMicros));
    } else {
      _poses.add(pose);
    }
    while (_poses.length > maxSamples) {
      _poses.removeAt(0);
    }
    final newest = _poses.last.timestampMicros;
    _poses.removeWhere((p) => newest - p.timestampMicros > maxAgeMicros);
  }

  ScanPose? nearest(int timestampMicros, {double minimumQuality = 0.0}) {
    ScanPose? best;
    var bestDistance = double.infinity;
    for (final pose in _poses) {
      if (pose.quality < minimumQuality) continue;
      final distance = (pose.timestampMicros - timestampMicros).abs().toDouble();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = pose;
      }
    }
    return best;
  }

  ScanPose? interpolate(int timestampMicros, {double minimumQuality = 0.0}) {
    if (_poses.isEmpty) return null;
    final nearestPose = nearest(timestampMicros, minimumQuality: minimumQuality);
    if (nearestPose == null) return null;

    ScanPose? before;
    ScanPose? after;
    for (final pose in _poses) {
      if (pose.quality < minimumQuality) continue;
      if (pose.timestampMicros <= timestampMicros) before = pose;
      if (pose.timestampMicros >= timestampMicros) {
        after = pose;
        break;
      }
    }
    if (before == null || after == null || before.timestampMicros == after.timestampMicros) {
      return nearestPose;
    }

    final span = after.timestampMicros - before.timestampMicros;
    if (span <= 0) return nearestPose;
    final t = ((timestampMicros - before.timestampMicros) / span).clamp(0.0, 1.0).toDouble();
    final quality = math.min(before.quality, after.quality);
    return ScanPose(
      timestampMicros: timestampMicros,
      x: before.x + (after.x - before.x) * t,
      y: before.y + (after.y - before.y) * t,
      z: before.z + (after.z - before.z) * t,
      qx: before.qx + (after.qx - before.qx) * t,
      qy: before.qy + (after.qy - before.qy) * t,
      qz: before.qz + (after.qz - before.qz) * t,
      qw: before.qw + (after.qw - before.qw) * t,
      quality: quality,
    );
  }
}
