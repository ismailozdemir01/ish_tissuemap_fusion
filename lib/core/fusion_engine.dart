import '../models/imaging_pipeline.dart';
import 'signal_feature.dart';

class FusionPoint {
  final int timestampMicros;
  final double value;
  final double uncertainty;
  final Set<SignalModality> modalities;

  const FusionPoint({required this.timestampMicros, required this.value, required this.uncertainty, required this.modalities});
}

/// Preserves heterogeneous modalities as typed features. Raw values are never
/// averaged across different physical units or physical meanings.
class FusionEngine {
  const FusionEngine();

  List<MultimodalFeatureSet> fuseFeatures(List<List<RawSignalSample>> synchronizedGroups) {
    final result = <MultimodalFeatureSet>[];
    for (final group in synchronizedGroups) {
      final features = <SignalFeature>[];
      for (final sample in group) {
        if (sample.values.isEmpty || sample.values.any((v) => !v.isFinite) || !sample.quality.isFinite || sample.quality <= 0 || sample.unit.isEmpty) continue;
        final quality = sample.quality.clamp(0.0, 1.0).toDouble();
        features.add(SignalFeature(
          featureId: '${sample.modality.name}:${sample.sensorId}:${sample.unit}',
          modality: sample.modality,
          sensorId: sample.sensorId,
          timestampMicros: sample.timestampMicros,
          values: List.unmodifiable(sample.values),
          unit: sample.unit,
          quality: quality,
          uncertainty: 1.0 - quality,
        ));
      }
      if (features.isNotEmpty) {
        result.add(MultimodalFeatureSet(timestampMicros: features.first.timestampMicros, features: List.unmodifiable(features)));
      }
    }
    return List.unmodifiable(result);
  }

  /// Legacy scalar fusion is allowed only for same-unit samples.
  List<FusionPoint> fuse(List<List<RawSignalSample>> synchronizedGroups) {
    final result = <FusionPoint>[];
    for (final group in synchronizedGroups) {
      final usable = group.where((s) => s.values.isNotEmpty && s.values.every((v) => v.isFinite) && s.quality.isFinite && s.quality > 0 && s.unit.isNotEmpty).toList();
      if (usable.isEmpty) continue;
      final units = usable.map((s) => s.unit).toSet();
      if (units.length != 1) continue;
      var weightedSum = 0.0;
      var totalWeight = 0.0;
      for (final sample in usable) {
        final value = sample.values.reduce((a, b) => a + b) / sample.values.length;
        final weight = sample.quality.clamp(0.0001, 1.0).toDouble();
        weightedSum += value * weight;
        totalWeight += weight;
      }
      final meanQuality = (totalWeight / usable.length).clamp(0.0, 1.0).toDouble();
      result.add(FusionPoint(
        timestampMicros: usable.first.timestampMicros,
        value: weightedSum / totalWeight,
        uncertainty: 1.0 - meanQuality,
        modalities: usable.map((s) => s.modality).toSet(),
      ));
    }
    return List.unmodifiable(result);
  }
}
