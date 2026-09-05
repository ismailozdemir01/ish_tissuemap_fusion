import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' as vm;

class AROverlayPainter extends CustomPainter {
  final vm.Vector2 estimatedPosition;
  final bool isScanning;

  AROverlayPainter({required this.estimatedPosition, required this.isScanning});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final textStyle = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [
      Shadow(blurRadius: 8, color: Colors.black87, offset: Offset(2, 2))
    ]);

    // 1. Vücut silueti (Örnek kontur)
    paint.color = Colors.cyanAccent.withOpacity(0.2);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    
    final bodyPath = Path();
    // Omuzdan başlayan bir taslak (Gerçekte SVG/PNG ile yapılır)
    bodyPath.moveTo(size.width * 0.2, size.height * 0.1);
    bodyPath.quadraticBezierTo(size.width * 0.1, size.height * 0.3, size.width * 0.15, size.height * 0.5);
    bodyPath.quadraticBezierTo(size.width * 0.1, size.height * 0.7, size.width * 0.2, size.height * 0.9);
    bodyPath.quadraticBezierTo(size.width * 0.5, size.height * 0.95, size.width * 0.8, size.height * 0.9);
    bodyPath.quadraticBezierTo(size.width * 0.9, size.height * 0.7, size.width * 0.85, size.height * 0.5);
    bodyPath.quadraticBezierTo(size.width * 0.9, size.height * 0.3, size.width * 0.8, size.height * 0.1);
    bodyPath.close();
    canvas.drawPath(bodyPath, paint);

    // 2. Organ Etiketleri (Sanal Anatomi)
    // Karaciğer (Sağ üst)
    _drawLabel(canvas, "Karaciğer", Offset(size.width * 0.65, size.height * 0.35));
    // Mide (Orta sol)
    _drawLabel(canvas, "Mide", Offset(size.width * 0.3, size.height * 0.4));
    // Dalak (Sol üst)
    _drawLabel(canvas, "Dalak", Offset(size.width * 0.25, size.height * 0.25));
    // Böbrekler (Orta)
    _drawLabel(canvas, "Sağ Böbrek", Offset(size.width * 0.7, size.height * 0.5));
    _drawLabel(canvas, "Sol Böbrek", Offset(size.width * 0.25, size.height * 0.55));

    // 3. CANLI NOKTA (Kullanıcının tahmini konumu)
    if (isScanning) {
      paint.color = Colors.red;
      paint.style = PaintingStyle.fill;
      Offset pos = Offset(
        estimatedPosition.x * size.width,
        estimatedPosition.y * size.height
      );
      canvas.drawCircle(pos, 15, paint);
      
      // Dalgalanma efekti
      paint.color = Colors.red.withOpacity(0.3);
      canvas.drawCircle(pos, 30, paint);
      
      // Bilgi yazısı
      TextSpan span = TextSpan(text: "🔄 Tarama Aktif", style: textStyle.copyWith(color: Colors.greenAccent));
      TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout(maxWidth: size.width);
      tp.paint(canvas, Offset(10, 10));
    } else {
      TextSpan span = TextSpan(text: "📱 Telefonu vücudunuzda gezdirin", style: textStyle);
      TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout(maxWidth: size.width);
      tp.paint(canvas, Offset(size.width/2 - tp.width/2, 10));
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, backgroundColor: Colors.black45)),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(canvas, offset - Offset(painter.width/2, painter.height/2));
  }

  @override
  bool shouldRepaint(covariant AROverlayPainter oldDelegate) => true;
}
