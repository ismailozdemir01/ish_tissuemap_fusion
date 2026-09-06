import '../models/imaging_pipeline.dart';

class SignalProcessingPipeline {
  const SignalProcessingPipeline();

  List<RawSignalSample> denoise(List<RawSignalSample> input) {
    return input.where((s) => s.values.isNotEmpty && s.quality > 0).map((s) {
      if (s.values.length < 3) return s;
      final filtered = <double>[];
      for (var i = 0; i < s.values.length; i++) {
        var sum = 0.0;
        var count = 0;
        for (var j = i - 1; j <= i + 1; j++) {
          if (j >= 0 && j < s.values.length) {
            sum += s.values[j];
            count++;
          }
        }
        filtered.add(sum / count);
      }
      return RawSignalSample(sensorId: s.sensorId, modality: s.modality, timestampMicros: s.timestampMicros, values: filtered, unit: s.unit, quality: s.quality);
    }).toList(growable: false);
  }

  List<double> normalize(List<double> values) {
    if (values.isEmpty) return const [];
    final maxAbs = values.map((v) => v.abs()).fold<double>(0, (a, b) => a > b ? a : b);
    if (maxAbs == 0) return List<double>.filled(values.length, 0);
    return values.map((v) => v / maxAbs).toList(growable: false);
  }
}
