import '../models/imaging_pipeline.dart';

class FusionPoint {
  final int timestampMicros;
  final double value;
  final double uncertainty;
  final Set<SignalModality> modalities;

  const FusionPoint({required this.timestampMicros, required this.value, required this.uncertainty, required this.modalities});
}

class FusionEngine {
  const FusionEngine();

  List<FusionPoint> fuse(List<List<RawSignalSample>> synchronizedGroups) {
    final result = <FusionPoint>[];
    for (final group in synchronizedGroups) {
      final usable = group.where((s) => s.values.isNotEmpty && s.quality > 0).toList();
      if (usable.isEmpty) continue;
      var weightedSum = 0.0;
      var totalWeight = 0.0;
      for (final sample in usable) {
        final value = sample.values.reduce((a, b) => a + b) / sample.values.length;
        final weight = sample.quality.clamp(0.0001, 1.0);
        weightedSum += value * weight;
        totalWeight += weight;
      }
      final value = weightedSum / totalWeight;
      final uncertainty = 1.0 - (totalWeight / usable.length).clamp(0.0, 1.0);
      result.add(FusionPoint(timestampMicros: usable.first.timestampMicros, value: value, uncertainty: uncertainty, modalities: usable.map((s) => s.modality).toSet()));
    }
    return result;
  }
}
