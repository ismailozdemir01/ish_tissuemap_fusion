import 'body_scan.dart';
import 'optical_frame.dart';

/// A camera frame linked to the closest/interpolated measured phone pose.
/// Registration does not imply camera-derived depth or internal anatomy.
class RegisteredOpticalFrame {
  final OpticalFrame frame;
  final ScanPose pose;
  final double poseUncertainty;
  final bool timestampInterpolated;

  const RegisteredOpticalFrame({
    required this.frame,
    required this.pose,
    required this.poseUncertainty,
    required this.timestampInterpolated,
  });

  bool get usable => pose.quality > 0 && poseUncertainty.isFinite;
}
