import 'dart:io';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';
import 'package:ish_tissuemap_fusion/services/analysis/chronos_service.dart';
import 'package:ish_tissuemap_fusion/services/sensor/fusion_engine.dart';

class PdfReportService {
  final ChronosService _chronos = ChronosService();

  Future<File> generateReport(ChronosSnapshot snapshot, FusionEngine engine) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (context) => pw.Column(
        children: [
          pw.Center(child: pw.Text('ISH TissueMap Fusion', style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          pw.Center(child: pw.Text('Sağlık Raporu', style: pw.TextStyle(fontSize: 24))),
          pw.SizedBox(height: 10),
          pw.Center(child: pw.Text('Tarih: ${snapshot.timestamp.toLocal()}', style: pw.TextStyle(fontSize: 16))),
          pw.SizedBox(height: 50),
          pw.Center(child: pw.Text('Özet Skor: ${(snapshot.averageFusionScore * 100).toInt()}%', style: pw.TextStyle(fontSize: 20))),
        ],
      ),
    ));

    final image = engine.generateHeatmap(200, 200);
    final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes != null) {
      final pngImage = pw.MemoryImage(pngBytes.buffer.asUint8List());
      pdf.addPage(pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Text('Isı Haritası', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 10),
            pw.Image(pngImage, width: 400, height: 400),
            pw.SizedBox(height: 20),
            pw.Text('*Bu görsel klinik tanı olarak yorumlanamaz.*'),
          ],
        ),
      ));
    }

    final allScans = await _chronos.loadAllScans();
    if (allScans.length > 1) {
      pdf.addPage(pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Text('Zaman Tüneli Trendi', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: allScans.reversed.take(5).map((s) => pw.TableRow(children: [
                pw.Text(s.timestamp.toLocal().toString().split(' ')[0]),
                pw.Text('${(s.averageFusionScore * 100).toInt()}%'),
              ])).toList(),
            ),
          ],
        ),
      ));
    }

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ISH_Rapor_${snapshot.id}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
}
