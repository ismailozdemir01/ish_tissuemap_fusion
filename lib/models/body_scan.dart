import 'imaging_pipeline.dart';

/// Anatomical region used only for spatial scan coverage bookkeeping.
enum BodyRegion {
  head,
  neck,
  chest,
  abdomen,
  pelvis,
  leftArm,
  rightArm,
  leftLeg,
  rightLeg,
  back,
}

class ScanPose {
  final int timestampMicros;
  final double x;
  final double y;
  final double z;
  final double qx;
  final double qy;
  final double qz;
  final double qw;
  final double quality;

  const ScanPose({
    required this.timestampMicros,
    required this.x,
    required this.y,
    required this.z,
    required this.qx,
    required this.qy,
    required this.qz,
    required this.qw,
    required this.quality,
  });
}

class SpatialAcquisitionSample {
  final RawSignalSample signal;
  final ScanPose pose;
  final BodyRegion? region;

  const SpatialAcquisitionSample({
    required this.signal,
    required this.pose,
    this.region,
  });
}

class ScanCoverage {
  final Set<BodyRegion> acquiredRegions;
  final int sampleCount;
  final double pathLengthMeters;
  final double quality;

  const ScanCoverage({
    this.acquiredRegions = const {},
    this.sampleCount = 0,
    this.pathLengthMeters = 0,
    this.quality = 0,
  });

  bool get hasAcquisition => sampleCount > 0;
}

class BodyScanSession {
  final String sessionId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final AcquisitionMode acquisitionMode;
  final ProcessingLocation processingLocation;
  final List<SpatialAcquisitionSample> samples;
  final ScanCoverage coverage;

  const BodyScanSession({
    required this.sessionId,
    required this.startedAt,
    this.endedAt,
    required this.acquisitionMode,
    required this.processingLocation,
    this.samples = const [],
    this.coverage = const ScanCoverage(),
  });

  bool get isComplete => endedAt != null;
}
