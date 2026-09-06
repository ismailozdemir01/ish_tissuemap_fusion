import 'dart:math' as math;

import '../models/rf_measurement.dart';

class RfFrequencyFeatureSet {
  final double frequencyMHz;
  final int sampleCount;
  final double baselineDbm;
  final double meanDbm;
  final double deltaDb;
  final double standardDeviationDb;
  final double temporalSlopeDbPerSecond;
  final double quality;

  const RfFrequencyFeatureSet({
    required this.frequencyMHz,
    required this.sampleCount,
    required this.baselineDbm,
    required this.meanDbm,
    required this.deltaDb,
    required this.standardDeviationDb,
    required this.temporalSlopeDbPerSecond,
    required this.quality,
  });
}

class RfCrossFrequencyFeature {
  final double lowerFrequencyMHz;
  final double upperFrequencyMHz;
  final double deltaDbDifference;
  final double meanDifferenceDb;
  final double quality;

  const RfCrossFrequencyFeature({
    required this.lowerFrequencyMHz,
    required this.upperFrequencyMHz,
    required this.deltaDbDifference,
    required this.meanDifferenceDb,
    required this.quality,
  });
}

/// Extracts independent real measurements per Wi-Fi frequency and derives
/// cross-frequency differences only when both frequencies were observed.
class RfMultifrequencyFeatureExtractor {
  const RfMultifrequencyFeatureExtractor();

  List<RfFrequencyFeatureSet> extract(
    Iterable<RfMeasurement> measurements, {
    Map<double, double>? baselineByFrequency,
  }) {
    final groups = <double, List<RfMeasurement>>{};
    for (final measurement in measurements) {
      if (!measurement.isUsable || measurement.rssiDbm == null) continue;
      groups.putIfAbsent(measurement.frequencyMHz, () => <RfMeasurement>[]).add(measurement);
    }

    final output = <RfFrequencyFeatureSet>[];
    for (final entry in groups.entries) {
      final ordered = [...entry.value]..sort((a, b) => a.timestampMicros.compareTo(b.timestampMicros));
      final values = ordered.map((m) => m.rssiDbm!).toList();
      final baseline = baselineByFrequency?[entry.key] ?? values.first;
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance = values.length == 1
          ? 0.0
          : values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
      final slope = _slope(ordered);
      final quality = ordered.map((m) => m.quality).reduce((a, b) => a + b) / ordered.length;
      output.add(RfFrequencyFeatureSet(
        frequencyMHz: entry.key,
        sampleCount: ordered.length,
        baselineDbm: baseline,
        meanDbm: mean,
        deltaDb: mean - baseline,
        standardDeviationDb: math.sqrt(variance),
        temporalSlopeDbPerSecond: slope,
        quality: quality,
      ));
    }
    output.sort((a, b) => a.frequencyMHz.compareTo(b.frequencyMHz));
    return output;
  }

  List<RfCrossFrequencyFeature> crossFrequency(List<RfFrequencyFeatureSet> features) {
    final output = <RfCrossFrequencyFeature>[];
    for (var i = 0; i < features.length; i++) {
      for (var j = i + 1; j < features.length; j++) {
        final a = features[i];
        final b = features[j];
        output.add(RfCrossFrequencyFeature(
          lowerFrequencyMHz: a.frequencyMHz,
          upperFrequencyMHz: b.frequencyMHz,
          deltaDbDifference: a.deltaDb - b.deltaDb,
          meanDifferenceDb: a.meanDbm - b.meanDbm,
          quality: math.min(a.quality, b.quality),
        ));
      }
    }
    return output;
  }

  double _slope(List<RfMeasurement> values) {
    if (values.length < 2) return 0;
    final t0 = values.first.timestampMicros;
    final xs = values.map((m) => (m.timestampMicros - t0) / 1000000.0).toList();
    final ys = values.map((m) => m.rssiDbm!).toList();
    final meanX = xs.reduce((a, b) => a + b) / xs.length;
    final meanY = ys.reduce((a, b) => a + b) / ys.length;
    var numerator = 0.0;
    var denominator = 0.0;
    for (var i = 0; i < xs.length; i++) {
      numerator += (xs[i] - meanX) * (ys[i] - meanY);
      denominator += (xs[i] - meanX) * (xs[i] - meanX);
    }
    return denominator == 0 ? 0 : numerator / denominator;
  }
}
