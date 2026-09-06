import 'visual_inertial_fusion_engine.dart';
import 'visual_motion_estimator.dart';

/// Runtime visual-pose capability. Implementations must return only measured
/// metric pose observations. Pixel motion alone must never be converted to m.
abstract class VisualPoseBackend {
  String get backendId;
  bool get available;

  Future<VisualPoseObservation?> observe({
    required int timestampMicros,
    required VisualMotionObservation motion,
  });

  Future<void> start();
  Future<void> stop();
}

class UnavailableVisualPoseBackend implements VisualPoseBackend {
  @override
  final String backendId;

  const UnavailableVisualPoseBackend({this.backendId = 'NONE'});

  @override
  bool get available => false;

  @override
  Future<VisualPoseObservation?> observe({required int timestampMicros, required VisualMotionObservation motion}) async => null;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class VisualPoseBackendRegistry {
  final List<VisualPoseBackend> backends;

  const VisualPoseBackendRegistry({this.backends = const []});

  VisualPoseBackend? get active {
    for (final backend in backends) {
      if (backend.available) return backend;
    }
    return null;
  }
}
