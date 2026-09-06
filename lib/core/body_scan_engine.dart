import 'dart:math' as math;

import '../models/body_scan.dart';

class BodyScanEngine {
  BodyScanEngine({this.minimumPoseQuality = 0.5});

  final double minimumPoseQuality;
  final List<SpatialAcquisitionSample> _samples = [];
  ScanPose? _lastPose;

  bool get isScanning => _samples.isNotEmpty;
  List<SpatialAcquisitionSample> get samples => List.unmodifiable(_samples);

  void add(SpatialAcquisitionSample sample) {
    if (!sample.signal.values.every((v) => v.isFinite)) {
      throw StateError('INVALID_NONFINITE_ACQUISITION_SAMPLE');
    }
    if (!sample.signal.quality.isFinite || sample.signal.quality < 0 || sample.signal.quality > 1) {
      throw StateError('INVALID_SIGNAL_QUALITY');
    }
    if (!sample.pose.quality.isFinite || sample.pose.quality < minimumPoseQuality) {
      return;
    }
    if (_lastPose != null && sample.pose.timestampMicros < _lastPose!.timestampMicros) {
      throw StateError('NON_MONOTONIC_SCAN_TIME');
    }
    _samples.add(sample);
    _lastPose = sample.pose;
  }

  ScanCoverage coverage() {
    final regions = <BodyRegion>{
      for (final sample in _samples)
        if (sample.region != null) sample.region!,
    };
    var path = 0.0;
    for (var i = 1; i < _samples.length; i++) {
      final a = _samples[i - 1].pose;
      final b = _samples[i].pose;
      final dx = b.x - a.x;
      final dy = b.y - a.y;
      final dz = b.z - a.z;
      path += math.sqrt(dx * dx + dy * dy + dz * dz);
    }
    return ScanCoverage(
      acquiredRegions: Set.unmodifiable(regions),
      sampleCount: _samples.length,
      pathLengthMeters: path,
      quality: _samples.isEmpty
          ? 0
          : _samples.map((s) => s.signal.quality * s.pose.quality).reduce((a, b) => a + b) / _samples.length,
    );
  }

  void clear() {
    _samples.clear();
    _lastPose = null;
  }
}
