import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';
import 'package:ish_tissuemap_fusion/services/sensor/fusion_engine.dart';
import 'package:ish_tissuemap_fusion/services/analysis/chronos_service.dart';

/// Tarama verilerini profesyonel PDF raporu olarak oluşturur.
class PdfReportService {
  final ChronosService _chronos = ChronosService();

  Future<File> generateReport(ChronosSnapshot snapshot, FusionEngine engine) async {
    final pdf = pw.Document();

    // Kapak
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

    // Isı haritası (görsel olarak)
    final image = engine.generateHeatmap(200, 200);
    final pngBytes = await image.toByteData(format: ImageByteFormat.png);
    final pngImage = pw.MemoryImage(pngBytes!.buffer.asUint8List());
    
    pdf.addPage(pw.Page(
      build: (context) => pw.Column(
        children: [
          pw.Text('Isı Haritası', style: pw.TextStyle(fontSize: 24)),
          pw.SizedBox(height: 10),
          pw.Image(pngImage, width: 400, height: 400),
          pw.SizedBox(height: 20),
          pw.Text('*Kırmızı bölgeler anormallik gösterebilir.*'),
        ],
      ),
    ));

    // Geçmiş trend (son 5 tarama varsa)
    final allScans = await _chronos.loadAllScans();
    if (allScans.length > 1) {
      pdf.addPage(pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Text('Zaman Tüneli Trendi', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 10),
            pw.Text('Skor değişimi: ${allScans.last.compareScore(allScans[allScans.length-2]) > 0 ? "Kötüleşme" : "İyileşme"}'),
            pw.Table(
              border: pw.TableBorder.all(),
              children: allScans.reversed.take(5).map((s) {
                return pw.TableRow(
                  children: [
                    pw.Text(s.timestamp.toLocal().toString().split(' ')[0]),
                    pw.Text((s.averageFusionScore * 100).toInt().toString() + '%'),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ));
    }

    // Sonuç
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ISH_Rapor_${snapshot.id}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
}
