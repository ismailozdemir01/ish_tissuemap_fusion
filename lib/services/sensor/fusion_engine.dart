import 'dart:math';
import 'dart:ui' as ui;

import 'package:ish_tissuemap_fusion/models/tissue_point.dart';

class FusionEngine {
  final int gridSize = 64;
  late List<List<double>> _heatmapGrid;
  final List<TissuePoint> _collectedPoints = [];

  FusionEngine() {
    _heatmapGrid = List.generate(gridSize, (_) => List.filled(gridSize, 0.0));
  }

  void addSample(TissuePoint point) {
    _collectedPoints.add(point);
    _recalculateGrid();
  }

  void _recalculateGrid() {
    if (_collectedPoints.isEmpty) return;
    for (var ix = 0; ix < gridSize; ix++) {
      for (var iy = 0; iy < gridSize; iy++) {
        final gridX = ix / gridSize;
        final gridY = iy / gridSize;
        var weightedSum = 0.0;
        var weightTotal = 0.0;
        for (final point in _collectedPoints) {
          final dist = sqrt(pow(gridX - point.x, 2) + pow(gridY - point.y, 2));
          if (dist < 0.001) {
            weightedSum = point.fusionScore;
            weightTotal = 1.0;
            break;
          }
          final weight = 1 / pow(dist, 2.0);
          weightedSum += point.fusionScore * weight;
          weightTotal += weight;
        }
        _heatmapGrid[ix][iy] = weightTotal > 0 ? weightedSum / weightTotal : 0.0;
      }
    }
  }

  ui.Image generateHeatmap(int width, int height) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();
    for (var ix = 0; ix < gridSize; ix++) {
      for (var iy = 0; iy < gridSize; iy++) {
        final val = _heatmapGrid[ix][iy];
        final r = (val * 255).clamp(0, 255).toInt();
        final g = ((1 - val) * 255).clamp(0, 255).toInt();
        final b = ((1 - val) * 180).clamp(0, 180).toInt();
        paint.color = ui.Color.fromARGB(200, r, g, b);
        canvas.drawRect(ui.Rect.fromLTWH(ix * (width / gridSize), iy * (height / gridSize), width / gridSize + 1, height / gridSize + 1), paint);
      }
    }
    return recorder.endRecording().toImageSync(width, height);
  }

  List<TissuePoint> get points => List.unmodifiable(_collectedPoints);

  void clear() {
    _collectedPoints.clear();
    _heatmapGrid = List.generate(gridSize, (_) => List.filled(gridSize, 0.0));
  }
}
