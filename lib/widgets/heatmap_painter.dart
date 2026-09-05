import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/services/sensor/fusion_engine.dart';

class HeatmapPainter extends CustomPainter {
  final FusionEngine engine;

  HeatmapPainter({required this.engine});

  @override
  void paint(Canvas canvas, Size size) {
    if (engine.points.isEmpty) {
      // Boşsa mesaj göster
      final textSpan = TextSpan(text: "Telefonu vücutta gezdirin", style: TextStyle(color: Colors.grey, fontSize: 20));
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout(maxWidth: size.width);
      tp.paint(canvas, Offset(size.width/2 - tp.width/2, size.height/2 - tp.height/2));
      return;
    }

    // Gerçek Isı Haritasını çiz
    final image = engine.generateHeatmap(size.width.toInt(), size.height.toInt());
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) => true;
}
