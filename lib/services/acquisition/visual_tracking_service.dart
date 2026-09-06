import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../core/visual_feature.dart';
import '../../core/visual_feature_tracker.dart';
import '../../core/visual_motion_estimator.dart';
import '../../models/optical_frame.dart';

class VisualTrackingService {
  final VisualFeatureTracker featureTracker;
  final VisualMotionEstimator motionEstimator;

  VisualFeatureSet? _previous;
  bool _running = false;

  VisualTrackingService({this.featureTracker = const VisualFeatureTracker(), this.motionEstimator = const VisualMotionEstimator()});

  bool get running => _running;

  void start() => _running = true;

  void stop() {
    _running = false;
    _previous = null;
  }

  Future<VisualTrackingResult> process(OpticalFrame frame) async {
    if (!_running) return VisualTrackingResult.unavailable(frame, 'VISUAL_TRACKING_NOT_STARTED');
    final file = File(frame.path);
    if (!await file.exists()) return VisualTrackingResult.unavailable(frame, 'CAMERA_FRAME_NOT_FOUND');
    return processBytes(frame, await file.readAsBytes());
  }

  VisualTrackingResult processBytes(OpticalFrame frame, Uint8List bytes) {
    if (!_running) return VisualTrackingResult.unavailable(frame, 'VISUAL_TRACKING_NOT_STARTED');
    final current = featureTracker.extract(frame, bytes);
    if (current.features.isEmpty) {
      _previous = current;
      return VisualTrackingResult.unavailable(frame, 'NO_TRACKABLE_VISUAL_FEATURES');
    }
    final previous = _previous;
    _previous = current;
    if (previous == null) {
      return VisualTrackingResult(frame: frame, features: current, matches: const [], motion: null, status: VisualTrackingStatus.initialized, reason: 'FIRST_FRAME_INITIALIZED');
    }
    final matches = featureTracker.match(previous, current);
    final motion = motionEstimator.estimate(previous, current, matches);
    if (!motion.valid) {
      return VisualTrackingResult(frame: frame, features: current, matches: matches, motion: motion, status: VisualTrackingStatus.insufficientData, reason: 'INSUFFICIENT_TRACKING_QUALITY');
    }
    return VisualTrackingResult(frame: frame, features: current, matches: matches, motion: motion, status: VisualTrackingStatus.valid, reason: 'REAL_FRAME_TO_FRAME_MOTION');
  }
}

enum VisualTrackingStatus { initialized, valid, insufficientData, unavailable }

class VisualTrackingResult {
  final OpticalFrame frame;
  final VisualFeatureSet? features;
  final List<VisualFeatureMatch> matches;
  final VisualMotionObservation? motion;
  final VisualTrackingStatus status;
  final String reason;

  const VisualTrackingResult({required this.frame, required this.features, required this.matches, required this.motion, required this.status, required this.reason});

  factory VisualTrackingResult.unavailable(OpticalFrame frame, String reason) => VisualTrackingResult(
    frame: frame,
    features: null,
    matches: const [],
    motion: null,
    status: VisualTrackingStatus.unavailable,
    reason: reason,
  );
}
