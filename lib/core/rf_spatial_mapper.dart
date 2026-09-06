import 'dart:math' as math;

import '../models/body_scan.dart';
import '../models/rf_measurement.dart';

class RfSpatialPoint {
  final double x;
  final double y;
  final double z;
  final double rssiDbm;
  final double frequencyMHz;
  final double quality;
  final double uncertaintyDb;

  const RfSpatialPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.rssiDbm,
    required this.frequencyMHz,
    required this.quality,
    required this.uncertaintyDb,
  });
}

/// Maps real RF observations into the phone's measured spatial trajectory.
/// It intentionally produces an RF field, not a fabricated anatomical image.
class RfSpatialMapper {
  final double minimumQuality;
  final double minimumBaselineSamples;
  final List<RfSpatialPoint> _points = [];

  RfSpatialMapper({this.minimumQuality = 0.25, this.minimumBaselineSamples = 5});

  List<RfSpatialPoint> get points => List.unmodifiable(_points);

  void add({required ScanPose pose, required RfMeasurement measurement}) {
    if (!measurement.isUsable || measurement.rssiDbm == null || measurement.frequencyMHz == null) return;
    if (measurement.quality < minimumQuality) return;
    if (![pose.x, pose.y, pose.z].every((v) => v.isFinite)) return;
    _points.add(RfSpatialPoint(
      x: pose.x,
      y: pose.y,
      z: pose.z,
      rssiDbm: measurement.rssiDbm!,
      frequencyMHz: measurement.frequencyMHz!,
      quality: measurement.quality,
      uncertaintyDb: (1 - measurement.quality) * 20,
    ));
  }

  double? baseline({double? frequencyMHz}) {
    final values = _points
        .where((p) => frequencyMHz == null || (p.frequencyMHz - frequencyMHz).abs() < 1e-6)
        .map((p) => p.rssiDbm)
        .where((v) => v.isFinite)
        .toList();
    if (values.length < minimumBaselineSamples) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? attenuationAt(RfSpatialPoint point, {double? baselineDbm}) {
    final base = baselineDbm ?? baseline(frequencyMHz: point.frequencyMHz);
    if (base == null || !base.isFinite) return null;
    return base - point.rssiDbm;
  }

  double coverageLengthMeters() {
    if (_points.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < _points.length; i++) {
      final a = _points[i - 1];
      final b = _points[i];
      total += math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2) + math.pow(b.z - a.z, 2));
    }
    return total;
  }
}
