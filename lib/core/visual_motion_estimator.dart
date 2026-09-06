import 'dart:math' as math;

import 'visual_feature_tracker.dart';

class VisualMotionObservation {
  final int timestampMicros;
  final double dxPixels;
  final double dyPixels;
  final double scale;
  final double quality;
  final double uncertaintyPixels;
  final int matchCount;

  const VisualMotionObservation({
    required this.timestampMicros,
    required this.dxPixels,
    required this.dyPixels,
    required this.scale,
    required this.quality,
    required this.uncertaintyPixels,
    required this.matchCount,
  });

  bool get valid =>
      dxPixels.isFinite &&
      dyPixels.isFinite &&
      scale.isFinite &&
      scale > 0 &&
      quality > 0 &&
      uncertaintyPixels.isFinite;
}

class VisualMotionEstimator {
  final int minimumMatches;
  final double maximumResidualPixels;

  const VisualMotionEstimator({
    this.minimumMatches = 8,
    this.maximumResidualPixels = 20,
  });

  VisualMotionObservation estimate(
    VisualFeatureSet previous,
    VisualFeatureSet current,
    List<VisualFeatureMatch> matches,
  ) {
    final valid = matches.where((m) => m.valid).toList(growable: false);
    if (valid.length < minimumMatches) {
      return VisualMotionObservation(
        timestampMicros: current.timestampMicros,
        dxPixels: 0,
        dyPixels: 0,
        scale: 1,
        quality: 0,
        uncertaintyPixels: double.infinity,
        matchCount: valid.length,
      );
    }

    final dx = _median(valid.map((m) => m.dx).toList());
    final dy = _median(valid.map((m) => m.dy).toList());
    final residuals = valid
        .map((m) => math.sqrt(math.pow(m.dx - dx, 2) + math.pow(m.dy - dy, 2)))
        .toList();
    final residual = _median(residuals);
    final inliers = residuals.where((v) => v <= maximumResidualPixels).length;
    final quality = (inliers / valid.length).clamp(0.0, 1.0).toDouble();

    // Monocular pixel motion has no absolute metric scale. Keep scale dimensionless.
    return VisualMotionObservation(
      timestampMicros: current.timestampMicros,
      dxPixels: dx,
      dyPixels: dy,
      scale: 1,
      quality: quality,
      uncertaintyPixels: residual.isFinite ? residual : double.infinity,
      matchCount: valid.length,
    );
  }

  double _median(List<double> values) {
    if (values.isEmpty) return double.nan;
    values.sort();
    final mid = values.length ~/ 2;
    return values.length.isOdd ? values[mid] : (values[mid - 1] + values[mid]) / 2;
  }
}
