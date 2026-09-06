import '../models/imaging_pipeline.dart';

class SensorSynchronizer {
  final int toleranceMicros;

  const SensorSynchronizer({this.toleranceMicros = 5000});

  List<List<RawSignalSample>> align(List<RawSignalSample> samples) {
    if (samples.isEmpty) return const [];
    final sorted = [...samples]..sort((a, b) => a.timestampMicros.compareTo(b.timestampMicros));
    final groups = <List<RawSignalSample>>[];
    for (final sample in sorted) {
      if (groups.isEmpty || sample.timestampMicros - groups.last.last.timestampMicros > toleranceMicros) {
        groups.add([sample]);
      } else {
        groups.last.add(sample);
      }
    }
    return groups.map((g) => List<RawSignalSample>.unmodifiable(g)).toList(growable: false);
  }
}
