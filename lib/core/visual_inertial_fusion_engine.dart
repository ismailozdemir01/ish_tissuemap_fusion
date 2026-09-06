import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../models/body_scan.dart';
import '../models/registered_optical_frame.dart';

/// A visual pose observation produced by a real visual-tracking backend.
/// The engine does not invent observations when a backend is unavailable.
class VisualPoseObservation {
  final int timestampMicros;
  final Vector3 position;
  final Quaternion orientation;
  final double quality;
  final double uncertaintyMeters;

  const VisualPoseObservation({
    required this.timestampMicros,
    required this.position,
    required this.orientation,
    required this.quality,
    required this.uncertaintyMeters,
  });

  bool get valid =>
      quality.isFinite && quality > 0 &&
      uncertaintyMeters.isFinite && uncertaintyMeters >= 0 &&
      position.x.isFinite && position.y.isFinite && position.z.isFinite &&
      orientation.x.isFinite && orientation.y.isFinite &&
      orientation.z.isFinite && orientation.w.isFinite;
}

/// Fuses a measured inertial pose with an independently measured visual pose.
/// This is a fusion primitive, not a visual tracker: feature extraction,
/// matching, SLAM/ARCore/ARKit and depth estimation must provide the visual
/// observation from real camera data.
class VisualInertialFusionEngine {
  const VisualInertialFusionEngine({this.minimumQuality = 0.25});

  final double minimumQuality;

  ScanPose? fuse({
    required ScanPose inertial,
    required VisualPoseObservation visual,
  }) {
    if (inertial.quality < minimumQuality || !visual.valid || visual.quality < minimumQuality) {
      return null;
    }

    final inertialWeight = _weight(inertial.quality, 1.0);
    final visualWeight = _weight(visual.quality, visual.uncertaintyMeters + 0.001);
    final total = inertialWeight + visualWeight;
    if (!total.isFinite || total <= 0) return null;

    final p = Vector3(
      (inertial.x * inertialWeight + visual.position.x * visualWeight) / total,
      (inertial.y * inertialWeight + visual.position.y * visualWeight) / total,
      (inertial.z * inertialWeight + visual.position.z * visualWeight) / total,
    );
    final iq = Quaternion(inertial.qx, inertial.qy, inertial.qz, inertial.qw);
    final vq = visual.orientation.clone()..normalize();
    final blended = Quaternion(
      iq.x * inertialWeight + vq.x * visualWeight,
      iq.y * inertialWeight + vq.y * visualWeight,
      iq.z * inertialWeight + vq.z * visualWeight,
      iq.w * inertialWeight + vq.w * visualWeight,
    )..normalize();

    final quality = math.min(1.0, (inertial.quality * inertialWeight + visual.quality * visualWeight) / total);
    return ScanPose(
      timestampMicros: visual.timestampMicros,
      x: p.x,
      y: p.y,
      z: p.z,
      qx: blended.x,
      qy: blended.y,
      qz: blended.z,
      qw: blended.w,
      quality: quality,
    );
  }

  double _weight(double quality, double uncertainty) {
    final denominator = math.max(0.000001, uncertainty * uncertainty);
    return quality / denominator;
  }

  RegisteredOpticalFrame? applyToFrame({
    required RegisteredOpticalFrame frame,
    required VisualPoseObservation visual,
  }) {
    final fused = fuse(inertial: frame.pose, visual: visual);
    if (fused == null) return null;
    return RegisteredOpticalFrame(
      frame: frame.frame,
      pose: fused,
      poseUncertainty: math.max(frame.poseUncertainty, visual.uncertaintyMeters),
      timestampInterpolated: frame.timestampInterpolated,
    );
  }
}
