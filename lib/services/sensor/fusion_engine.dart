import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:ish_tissuemap_fusion/models/tissue_point.dart';
import 'dart:math';

class FusionEngine {
  final int gridSize = 64; // 64x64 piksel harita
  late List<List<double>> _heatmapGrid;
  List<TissuePoint> _collectedPoints = [];

  FusionEngine() {
    _heatmapGrid = List.generate(gridSize, (_) => List.filled(gridSize, 0.0));
  }

  void addSample(TissuePoint point) {
    _collectedPoints.add(point);
    _recalculateGrid();
  }

  // Ters Mesafe Ağırlıklı (IDW) Gerçek Interpolasyon
  void _recalculateGrid() {
    if (_collectedPoints.isEmpty) return;

    for (int ix = 0; ix < gridSize; ix++) {
      for (int iy = 0; iy < gridSize; iy++) {
        double gridX = ix / gridSize;
        double gridY = iy / gridSize;

        double weightedSum = 0.0;
        double weightTotal = 0.0;
        double power = 2.0; // IDW üssü

        for (var point in _collectedPoints) {
          double dist = sqrt(pow(gridX - point.x, 2) + pow(gridY - point.y, 2));
          if (dist < 0.001) {
            weightedSum = point.fusionScore;
            weightTotal = 1.0;
            break;
          }
          double weight = 1 / pow(dist, power);
          weightedSum += point.fusionScore * weight;
          weightTotal += weight;
        }
        _heatmapGrid[ix][iy] = (weightTotal > 0) ? weightedSum / weightTotal : 0.0;
      }
    }
  }

  // UI için Grafik (Bitmap) oluştur - Gerçek Renk Haritası
  ui.Image generateHeatmap(int width, int height) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    for (int ix = 0; ix < gridSize; ix++) {
      for (int iy = 0; iy < gridSize; iy++) {
        double val = _heatmapGrid[ix][iy];
        // Kırmızı (anormal) -> Sarı -> Yeşil -> Mavi (normal)
        int r = (val * 255).clamp(0, 255).toInt();
        int g = ((1 - val) * 255).clamp(0, 255).toInt();
        int b = ((1 - val) * 180).clamp(0, 180).toInt();

        paint.color = Color.fromARGB(200, r, g, b);
        canvas.drawRect(
          Rect.fromLTWH(
            ix * (width / gridSize),
            iy * (height / gridSize),
            width / gridSize + 1,
            height / gridSize + 1,
          ),
          paint,
        );
      }
    }

    return recorder.endRecording().toImageSync(width, height);
  }

  List<TissuePoint> get points => _collectedPoints;
  void clear() { _collectedPoints.clear(); _heatmapGrid = List.generate(gridSize, (_) => List.filled(gridSize, 0.0)); }
}
