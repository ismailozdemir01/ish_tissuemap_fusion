import '../models/imaging_pipeline.dart';

class SignalProcessingPipeline {
  const SignalProcessingPipeline();

  /// Applies a three-sample temporal moving average independently to each
  /// component of a sensor vector. Samples are never mixed across sensors,
  /// modalities, or units.
  List<RawSignalSample> denoise(List<RawSignalSample> input) {
    final usable = input.where((s) {
      return s.values.isNotEmpty &&
          s.values.every((v) => v.isFinite) &&
          s.quality.isFinite &&
          s.quality > 0 &&
          s.unit.isNotEmpty;
    }).toList();
    usable.sort((a, b) => a.timestampMicros.compareTo(b.timestampMicros));

    final result = <RawSignalSample>[];
    for (var i = 0; i < usable.length; i++) {
      final current = usable[i];
      final compatible = <RawSignalSample>[];
      for (var j = i - 1; j <= i + 1; j++) {
        if (j < 0 || j >= usable.length) continue;
        final candidate = usable[j];
        if (candidate.sensorId == current.sensorId &&
            candidate.modality == current.modality &&
            candidate.unit == current.unit &&
            candidate.values.length == current.values.length) {
          compatible.add(candidate);
        }
      }
      final filtered = List<double>.generate(current.values.length, (axis) {
        var sum = 0.0;
        for (final sample in compatible) {
          sum += sample.values[axis];
        }
        return sum / compatible.length;
      }, growable: false);
      result.add(RawSignalSample(
        sensorId: current.sensorId,
        modality: current.modality,
        timestampMicros: current.timestampMicros,
        values: filtered,
        unit: current.unit,
        quality: current.quality.clamp(0.0, 1.0).toDouble(),
      ));
    }
    return List.unmodifiable(result);
  }

  List<double> normalize(List<double> values) {
    if (values.isEmpty || values.any((v) => !v.isFinite)) return const [];
    final maxAbs = values.map((v) => v.abs()).fold<double>(0, (a, b) => a > b ? a : b);
    if (maxAbs == 0) return List<double>.filled(values.length, 0);
    return List.unmodifiable(values.map((v) => v / maxAbs));
  }
}
