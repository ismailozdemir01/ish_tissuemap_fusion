import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'optical_frame.dart';
import 'visual_feature.dart';

class VisualFeatureTracker {
  final int maxFeatures;
  final int patchRadius;
  final int minDistance;
  final double responseThreshold;

  const VisualFeatureTracker({
    this.maxFeatures = 200,
    this.patchRadius = 2,
    this.minDistance = 8,
    this.responseThreshold = 18,
  });

  VisualFeatureSet extract(OpticalFrame frame, Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return VisualFeatureSet(
        framePath: frame.path,
        timestampMicros: frame.timestampMicros,
        width: frame.width,
        height: frame.height,
        features: const [],
      );
    }

    final image = img.grayscale(decoded);
    final candidates = <VisualFeature>[];
    final r = patchRadius;
    for (var y = r + 1; y < image.height - r - 1; y += 2) {
      for (var x = r + 1; x < image.width - r - 1; x += 2) {
        final c = _gray(image, x, y);
        final gx = _gray(image, x + 1, y) - _gray(image, x - 1, y);
        final gy = _gray(image, x, y + 1) - _gray(image, x, y - 1);
        final response = math.sqrt(gx * gx + gy * gy);
        if (response < responseThreshold) continue;
        final descriptor = _descriptor(image, x, y, r);
        candidates.add(VisualFeature(
          x: x,
          y: y,
          descriptor: descriptor,
          response: response + c * 0.001,
        ));
      }
    }

    candidates.sort((a, b) => b.response.compareTo(a.response));
    final selected = <VisualFeature>[];
    final minD2 = minDistance * minDistance;
    for (final candidate in candidates) {
      if (selected.every((f) {
        final dx = f.x - candidate.x;
        final dy = f.y - candidate.y;
        return dx * dx + dy * dy >= minD2;
      })) {
        selected.add(candidate);
        if (selected.length >= maxFeatures) break;
      }
    }

    return VisualFeatureSet(
      framePath: frame.path,
      timestampMicros: frame.timestampMicros,
      width: image.width,
      height: image.height,
      features: selected,
    );
  }

  List<VisualFeatureMatch> match(VisualFeatureSet previous, VisualFeatureSet current,
      {double maxDistance = 0.35}) {
    final matches = <VisualFeatureMatch>[];
    for (final a in previous.features) {
      VisualFeature? best;
      var bestDistance = double.infinity;
      for (final b in current.features) {
        final d = _descriptorDistance(a.descriptor, b.descriptor);
        if (d < bestDistance) {
          bestDistance = d;
          best = b;
        }
      }
      if (best != null && bestDistance <= maxDistance) {
        matches.add(VisualFeatureMatch(a: a, b: best, distance: bestDistance));
      }
    }
    return matches;
  }

  double _gray(img.Image image, int x, int y) =>
      img.getLuminance(image.getPixel(x, y)).toDouble();

  List<double> _descriptor(img.Image image, int cx, int cy, int r) {
    final values = <double>[];
    var mean = 0.0;
    var count = 0;
    for (var y = -r; y <= r; y++) {
      for (var x = -r; x <= r; x++) {
        final v = _gray(image, cx + x, cy + y);
        values.add(v);
        mean += v;
        count++;
      }
    }
    mean /= count;
    var norm = 0.0;
    for (var i = 0; i < values.length; i++) {
      values[i] -= mean;
      norm += values[i] * values[i];
    }
    norm = math.sqrt(norm);
    if (norm < 1e-9) return List<double>.filled(values.length, 0);
    return values.map((v) => v / norm).toList(growable: false);
  }

  double _descriptorDistance(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return double.infinity;
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      final d = a[i] - b[i];
      sum += d * d;
    }
    return math.sqrt(sum / a.length);
  }
}

class VisualFeatureMatch {
  final VisualFeature a;
  final VisualFeature b;
  final double distance;

  const VisualFeatureMatch({required this.a, required this.b, required this.distance});

  double get dx => (b.x - a.x).toDouble();
  double get dy => (b.y - a.y).toDouble();
  bool get valid => distance.isFinite && distance >= 0;
}
