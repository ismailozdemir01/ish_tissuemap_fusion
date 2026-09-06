import '../models/body_scan.dart';
import '../models/optical_frame.dart';
import '../models/registered_optical_frame.dart';
import 'pose_history.dart';

/// Registers real camera frames against measured/interpolated phone poses.
/// No depth, tissue property, or anatomical value is inferred here.
class OpticalRegistrationEngine {
  const OpticalRegistrationEngine({this.minimumPoseQuality = 0.25});

  final double minimumPoseQuality;

  RegisteredOpticalFrame? register(
    OpticalFrame frame,
    PoseHistory history, {
    double poseUncertainty = 0.0,
  }) {
    final pose = history.interpolate(
      frame.timestampMicros,
      minimumQuality: minimumPoseQuality,
    );
    if (pose == null) return null;
    final nearest = history.nearest(
      frame.timestampMicros,
      minimumQuality: minimumPoseQuality,
    );
    if (nearest == null) return null;
    final ageMicros = (nearest.timestampMicros - frame.timestampMicros).abs();
    if (ageMicros > history.maxAgeMicros) return null;
    return RegisteredOpticalFrame(
      frame: frame,
      pose: pose,
      poseUncertainty: poseUncertainty,
      timestampInterpolated: nearest.timestampMicros != frame.timestampMicros,
    );
  }
}
