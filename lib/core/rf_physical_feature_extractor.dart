import 'dart:math' as math;

import '../models/rf_measurement.dart';

/// Physical RF observables derived only from real phone RF measurements.
/// These features describe propagation changes; they are not tissue labels.
class RfPhysicalFeature {
  final double? frequencyMHz;
  final int sampleCount;
  final double baselineRssiDbm;
  final double currentRssiDbm;
  final double deltaRssiDb;
  final double meanRssiDbm;
  final double standardDeviationDb;
  final double temporalSlopeDbPerSecond;
  final double quality;

  const RfPhysicalFeature({
    required this.frequencyMHz,
    required this.sampleCount,
    required this.baselineRssiDbm,
    required this.currentRssiDbm,
    required this.deltaRssiDb,
    required this.meanRssiDbm,
    required this.standardDeviationDb,
    required this.temporalSlopeDbPerSecond,
    required this.quality,
  });
}

class RfPhysicalFeatureExtractor {
  const RfPhysicalFeatureExtractor({this.minimumQuality = 0.25});

  final double minimumQuality;

  List<RfPhysicalFeature> extract(
    List<RfMeasurement> measurements, {
    Map<double?, double>? baselineByFrequency,
  }) {
    final usable = measurements
        .where((m) => m.isUsable && (m.frequencyMHz == null || m.frequencyMHz!.isFinite))
        .where((m) => m.quality >= minimumQuality)
        .toList()
      ..sort((a, b) => a.timestampMicros.compareTo(b.timestampMicros));

    final frequencies = <double?>{};
    for (final measurement in usable) frequencies.add(measurement.frequencyMHz);

    final result = <RfPhysicalFeature>[];
    for (final frequency in frequencies) {
      final group = usable.where((m) => m.frequencyMHz == frequency).toList();
      if (group.isEmpty) continue;
      final values = group.map((m) => m.rssiDbm!).toList();
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance = values.fold<double>(0, (sum, value) {
        final d = value - mean;
        return sum + d * d;
      }) / values.length;
      final baseline = baselineByFrequency?[frequency] ?? values.first;
      final current = values.last;
      final slope = _slope(group);
      final quality = group.map((m) => m.quality).reduce((a, b) => a + b) / group.length;
      result.add(RfPhysicalFeature(
        frequencyMHz: frequency,
        sampleCount: group.length,
        baselineRssiDbm: baseline,
        currentRssiDbm: current,
        deltaRssiDb: current - baseline,
        meanRssiDbm: mean,
        standardDeviationDb: math.sqrt(variance),
        temporalSlopeDbPerSecond: slope,
        quality: quality,
      ));
    }
    return result;
  }

  double _slope(List<RfMeasurement> group) {
    if (group.length < 2) return 0;
    final t0 = group.first.timestampMicros;
    final xs = group.map((m) => (m.timestampMicros - t0) / 1000000.0).toList();
    final ys = group.map((m) => m.rssiDbm!).toList();
    final meanX = xs.reduce((a, b) => a + b) / xs.length;
    final meanY = ys.reduce((a, b) => a + b) / ys.length;
    var numerator = 0.0;
    var denominator = 0.0;
    for (var i = 0; i < xs.length; i++) {
      final dx = xs[i] - meanX;
      numerator += dx * (ys[i] - meanY);
      denominator += dx * dx;
    }
    if (denominator == 0 || !denominator.isFinite) return 0;
    final slope = numerator / denominator;
    return slope.isFinite ? slope : 0;
  }
}
