import '../models/imaging_pipeline.dart';

class SensorSynchronizer {
  final int toleranceMicros;

  const SensorSynchronizer({this.toleranceMicros = 5000});

  /// Groups samples by proximity to the first sample in each group.
  /// This prevents a long chain of near-neighbour timestamps from exceeding
  /// the configured synchronization tolerance.
  List<List<RawSignalSample>> align(List<RawSignalSample> samples) {
    if (samples.isEmpty) return const [];
    if (toleranceMicros < 0) {
      throw ArgumentError.value(toleranceMicros, 'toleranceMicros', 'must be >= 0');
    }

    final sorted = [...samples]..sort((a, b) => a.timestampMicros.compareTo(b.timestampMicros));
    final groups = <List<RawSignalSample>>[];
    for (final sample in sorted) {
      if (groups.isEmpty) {
        groups.add([sample]);
        continue;
      }
      final anchor = groups.last.first.timestampMicros;
      if (sample.timestampMicros - anchor <= toleranceMicros) {
        groups.last.add(sample);
      } else {
        groups.add([sample]);
      }
    }
    return groups.map((g) => List<RawSignalSample>.unmodifiable(g)).toList(growable: false);
  }
}
