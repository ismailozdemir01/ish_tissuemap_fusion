import 'dart:math' as math;

import 'pose_history.dart';
import 'visual_motion_estimator.dart';
import '../models/body_scan.dart';
import '../models/rf_measurement.dart';
import 'rf_spatial_mapper.dart';

/// Keeps metric pose, non-metric optical motion and RF observations in one
/// coordinate-fusion state without inventing a pixel-to-meter scale.
class CommonCoordinateFusionState {
  final ScanPose? metricPose;
  final double opticalDxPixels;
  final double opticalDyPixels;
  final double opticalQuality;
  final double opticalUncertaintyPixels;
  final int opticalObservationCount;
  final int rfObservationCount;
  final double coordinateQuality;
  final double positionUncertaintyMeters;
  final String provenance;

  const CommonCoordinateFusionState({
    required this.metricPose,
    required this.opticalDxPixels,
    required this.opticalDyPixels,
    required this.opticalQuality,
    required this.opticalUncertaintyPixels,
    required this.opticalObservationCount,
    required this.rfObservationCount,
    required this.coordinateQuality,
    required this.positionUncertaintyMeters,
    required this.provenance,
  });

  static const empty = CommonCoordinateFusionState(
    metricPose: null,
    opticalDxPixels: 0,
    opticalDyPixels: 0,
    opticalQuality: 0,
    opticalUncertaintyPixels: double.infinity,
    opticalObservationCount: 0,
    rfObservationCount: 0,
    coordinateQuality: 0,
    positionUncertaintyMeters: double.infinity,
    provenance: 'NO_MEASURED_COORDINATE_DATA',
  );
}

class CommonCoordinateFusionEngine {
  final double minimumPoseQuality;
  final double maximumPixelResidual;
  final double visualWeight;
  final PoseHistory poseHistory;
  final RfSpatialMapper rfMapper;

  ScanPose? _metricPose;
  double _opticalDx = 0;
  double _opticalDy = 0;
  double _opticalQuality = 0;
  double _opticalUncertainty = double.infinity;
  int _opticalCount = 0;
  int _rfCount = 0;

  CommonCoordinateFusionEngine({
    this.minimumPoseQuality = 0.25,
    this.maximumPixelResidual = 20,
    this.visualWeight = 0.35,
    PoseHistory? poseHistory,
    RfSpatialMapper? rfMapper,
  })  : poseHistory = poseHistory ?? PoseHistory(),
        rfMapper = rfMapper ?? RfSpatialMapper();

  CommonCoordinateFusionState get state {
    final pose = _metricPose;
    final poseQuality = pose?.quality ?? 0;
    final opticalQuality = _opticalQuality;
    final quality = math.max(poseQuality, opticalQuality * visualWeight).clamp(0.0, 1.0).toDouble();
    return CommonCoordinateFusionState(
      metricPose: pose,
      opticalDxPixels: _opticalDx,
      opticalDyPixels: _opticalDy,
      opticalQuality: opticalQuality,
      opticalUncertaintyPixels: _opticalUncertainty,
      opticalObservationCount: _opticalCount,
      rfObservationCount: _rfCount,
      coordinateQuality: quality,
      positionUncertaintyMeters: pose == null ? double.infinity : _poseUncertaintyMeters(pose),
      provenance: _provenance(pose),
    );
  }

  void reset({ScanPose? anchor}) {
    _metricPose = anchor;
    _opticalDx = 0;
    _opticalDy = 0;
    _opticalQuality = 0;
    _opticalUncertainty = double.infinity;
    _opticalCount = 0;
    _rfCount = 0;
    poseHistory.clear();
    if (anchor != null) poseHistory.add(anchor);
  }

  /// Adds an already metric, measured pose. No visual scale conversion occurs.
  bool addMeasuredPose(ScanPose pose) {
    if (!_validPose(pose) || pose.quality < minimumPoseQuality) return false;
    _metricPose = pose;
    poseHistory.add(pose);
    return true;
  }

  /// Adds frame-to-frame optical motion. Pixel motion remains non-metric.
  bool addVisualMotion(VisualMotionObservation motion) {
    if (!motion.valid || motion.quality <= 0 || motion.uncertaintyPixels > maximumPixelResidual) return false;
    _opticalDx += motion.dxPixels;
    _opticalDy += motion.dyPixels;
    _opticalQuality = (_opticalQuality * _opticalCount + motion.quality) / (_opticalCount + 1);
    _opticalUncertainty = _opticalCount == 0
        ? motion.uncertaintyPixels
        : math.sqrt(_opticalUncertainty * _opticalUncertainty + motion.uncertaintyPixels * motion.uncertaintyPixels);
    _opticalCount++;
    return true;
  }

  /// Associates a real RF observation with the closest measured metric pose.
  bool addRfMeasurement(RfMeasurement measurement) {
    if (!measurement.isUsable || measurement.rssiDbm == null) return false;
    final pose = poseHistory.interpolate(measurement.timestampMicros, minimumQuality: minimumPoseQuality);
    if (pose == null) return false;
    rfMapper.add(
      RfSpatialPoint(
        x: pose.x,
        y: pose.y,
        z: pose.z,
        rssiDbm: measurement.rssiDbm!,
        frequencyMHz: measurement.frequencyMHz,
        quality: measurement.quality,
        uncertaintyDb: _poseUncertaintyDb(pose),
      ),
      measurement,
    );
    _rfCount++;
    return true;
  }

  CommonCoordinateFusionState fuse({
    ScanPose? measuredPose,
    VisualMotionObservation? visualMotion,
    RfMeasurement? rfMeasurement,
  }) {
    if (measuredPose != null) addMeasuredPose(measuredPose);
    if (visualMotion != null) addVisualMotion(visualMotion);
    if (rfMeasurement != null) addRfMeasurement(rfMeasurement);
    return state;
  }

  bool _validPose(ScanPose pose) =>
      pose.x.isFinite && pose.y.isFinite && pose.z.isFinite &&
      pose.qx.isFinite && pose.qy.isFinite && pose.qz.isFinite && pose.qw.isFinite &&
      pose.quality.isFinite && pose.quality > 0;

  double _poseUncertaintyMeters(ScanPose pose) {
    // Quality is a confidence indicator, not a manufactured physical error bar.
    // Keep this conservative and explicitly marked as an engineering estimate.
    return (1.0 - pose.quality).clamp(0.0, 1.0).toDouble();
  }

  double _poseUncertaintyDb(ScanPose pose) => 1.0 + _poseUncertaintyMeters(pose) * 5.0;

  String _provenance(ScanPose? pose) {
    if (pose != null && _rfCount > 0 && _opticalCount > 0) return 'MEASURED_IMU_POSE_PLUS_OPTICAL_CONSTRAINT_PLUS_RF';
    if (pose != null && _rfCount > 0) return 'MEASURED_IMU_POSE_PLUS_RF';
    if (pose != null && _opticalCount > 0) return 'MEASURED_IMU_POSE_PLUS_NON_METRIC_OPTICAL';
    if (pose != null) return 'MEASURED_INERTIAL_POSE';
    if (_opticalCount > 0) return 'NON_METRIC_OPTICAL_ONLY';
    return 'NO_MEASURED_COORDINATE_DATA';
  }
}
