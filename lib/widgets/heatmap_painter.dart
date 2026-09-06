import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/services/sensor/fusion_engine.dart';

class HeatmapPainter extends CustomPainter {
  final FusionEngine engine;
  final double opacity;

  const HeatmapPainter({required this.engine, this.opacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (engine.points.isEmpty) {
      final textSpan = const TextSpan(
          text: "Telefonu vücutta gezdirin",
          style: TextStyle(color: Colors.grey, fontSize: 20));
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout(maxWidth: size.width);
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
      return;
    }

    // Noktaları çiz
    for (var point in engine.points) {
      double x = point.x * size.width;
      double y = point.y * size.height;
      double radius = 10 + (point.fusionScore * 20);
      final paint = Paint()
        ..color = Color.fromRGBO(
          (255 * point.fusionScore).toInt().clamp(0, 255),
          (255 * (1 - point.fusionScore)).toInt().clamp(0, 255),
          0,
          150,
        )
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    return oldDelegate.engine.points.length != engine.points.length;
  }
}
