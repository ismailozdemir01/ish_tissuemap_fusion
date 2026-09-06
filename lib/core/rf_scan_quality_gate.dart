import '../models/body_scan.dart';
import '../models/imaging_pipeline.dart';

class RfScanQualityAssessment {
  final bool accepted;
  final int measurementCount;
  final int uniqueFrequencyCount;
  final double pathLengthMeters;
  final double meanQuality;
  final String reason;

  const RfScanQualityAssessment({
    required this.accepted,
    required this.measurementCount,
    required this.uniqueFrequencyCount,
    required this.pathLengthMeters,
    required this.meanQuality,
    required this.reason,
  });
}

/// Rejects RF scans that do not contain enough real observations or spatial
/// coverage for the configured reconstruction experiment. Thresholds are
/// configuration, not clinical claims.
class RfScanQualityGate {
  final int minimumMeasurements;
  final int minimumUniqueFrequencies;
  final double minimumPathLengthMeters;
  final double minimumMeanQuality;

  const RfScanQualityGate({
    this.minimumMeasurements = 20,
    this.minimumUniqueFrequencies = 1,
    this.minimumPathLengthMeters = 0.10,
    this.minimumMeanQuality = 0.25,
  });

  RfScanQualityAssessment assess(Iterable<SpatialAcquisitionSample> acquisition) {
    final samples = acquisition.where((sample) {
      final signal = sample.signal;
      return signal.modality == SignalModality.radioFrequency &&
          signal.values.isNotEmpty &&
          signal.values.first.isFinite &&
          signal.frequencyMHz != null &&
          signal.frequencyMHz!.isFinite &&
          signal.frequencyMHz! > 0 &&
          signal.quality.isFinite &&
          signal.quality > 0 &&
          sample.pose.x.isFinite &&
          sample.pose.y.isFinite &&
          sample.pose.z.isFinite;
    }).toList();

    final frequencies = samples.map((s) => s.signal.frequencyMHz!).toSet();
    var qualitySum = 0.0;
    for (final sample in samples) {
      qualitySum += sample.signal.quality.clamp(0.0, 1.0).toDouble();
    }
    final meanQuality = samples.isEmpty ? 0.0 : qualitySum / samples.length;
    final pathLength = _pathLength(samples);

    if (samples.length < minimumMeasurements) {
      return RfScanQualityAssessment(
        accepted: false,
        measurementCount: samples.length,
        uniqueFrequencyCount: frequencies.length,
        pathLengthMeters: pathLength,
        meanQuality: meanQuality,
        reason: 'INSUFFICIENT_RF_MEASUREMENTS',
      );
    }
    if (frequencies.length < minimumUniqueFrequencies) {
      return RfScanQualityAssessment(
        accepted: false,
        measurementCount: samples.length,
        uniqueFrequencyCount: frequencies.length,
        pathLengthMeters: pathLength,
        meanQuality: meanQuality,
        reason: 'INSUFFICIENT_RF_FREQUENCY_DIVERSITY',
      );
    }
    if (pathLength < minimumPathLengthMeters) {
      return RfScanQualityAssessment(
        accepted: false,
        measurementCount: samples.length,
        uniqueFrequencyCount: frequencies.length,
        pathLengthMeters: pathLength,
        meanQuality: meanQuality,
        reason: 'INSUFFICIENT_SPATIAL_COVERAGE',
      );
    }
    if (meanQuality < minimumMeanQuality) {
      return RfScanQualityAssessment(
        accepted: false,
        measurementCount: samples.length,
        uniqueFrequencyCount: frequencies.length,
        pathLengthMeters: pathLength,
        meanQuality: meanQuality,
        reason: 'LOW_RF_MEAN_QUALITY',
      );
    }
    return RfScanQualityAssessment(
      accepted: true,
      measurementCount: samples.length,
      uniqueFrequencyCount: frequencies.length,
      pathLengthMeters: pathLength,
      meanQuality: meanQuality,
      reason: 'RF_SCAN_OBSERVABILITY_ACCEPTED',
    );
  }

  double _pathLength(List<SpatialAcquisitionSample> samples) {
    if (samples.length < 2) return 0.0;
    var total = 0.0;
    var previous = samples.first.pose;
    for (final sample in samples.skip(1)) {
      final current = sample.pose;
      final dx = current.x - previous.x;
      final dy = current.y - previous.y;
      final dz = current.z - previous.z;
      total += (dx * dx + dy * dy + dz * dz).sqrt();
      previous = current;
    }
    return total;
  }
}

extension on double {
  double sqrt() {
    var x = this;
    if (x <= 0) return 0.0;
    var guess = x > 1 ? x / 2 : 1.0;
    for (var i = 0; i < 12; i++) {
      guess = 0.5 * (guess + x / guess);
    }
    return guess;
  }
}
