import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../lib/core/visual_feature_tracker.dart';
import '../lib/core/visual_motion_estimator.dart';
import '../lib/models/optical_frame.dart';
import '../lib/services/acquisition/visual_tracking_service.dart';

Uint8List _testImage({int shiftX = 0}) {
  final image = img.Image(width: 96, height: 96);
  img.fill(image, color: img.ColorRgb8(0, 0, 0));
  for (var y = 20; y < 76; y++) {
    for (var x = 20; x < 76; x++) {
      final px = x + shiftX;
      if (px >= 2 && px < 94) {
        image.setPixelRgb(px, y, (x * 3) % 255, (y * 3) % 255, ((x + y) * 2) % 255);
      }
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

OpticalFrame _frame(int timestamp) => OpticalFrame(
      path: 'test-$timestamp.png',
      timestampMicros: timestamp,
      width: 96,
      height: 96,
      format: 'png',
      cameraId: 'test-camera',
    );

void main() {
  test('extractor produces only features measured from image bytes', () {
    const tracker = VisualFeatureTracker(maxFeatures: 50);
    final set = tracker.extract(_frame(1), _testImage());
    expect(set.features, isNotEmpty);
    expect(set.features.every((f) => f.valid), isTrue);
  });

  test('frame matching detects measured image displacement', () {
    const tracker = VisualFeatureTracker(maxFeatures: 100, responseThreshold: 5);
    final a = tracker.extract(_frame(1), _testImage());
    final b = tracker.extract(_frame(2), _testImage(shiftX: 3));
    final matches = tracker.match(a, b, maxDistance: 0.6);
    expect(matches, isNotEmpty);
    final motion = const VisualMotionEstimator(minimumMatches: 1).estimate(a, b, matches);
    expect(motion.matchCount, greaterThan(0));
    expect(motion.valid, isTrue);
  });

  test('tracking service reports first frame without inventing motion', () {
    final service = VisualTrackingService(
      featureTracker: const VisualFeatureTracker(maxFeatures: 50, responseThreshold: 5),
      motionEstimator: const VisualMotionEstimator(minimumMatches: 1),
    );
    service.start();
    final first = service.processBytes(_frame(1), _testImage());
    expect(first.status, VisualTrackingStatus.initialized);
    expect(first.motion, isNull);
    service.stop();
  });
}
