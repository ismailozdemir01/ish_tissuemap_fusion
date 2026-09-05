import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/services/analysis/chronos_service.dart';
import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:intl/intl.dart';

class TimelineScreen extends StatefulWidget {
  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final ChronosService _chronos = ChronosService();
  List<ChronosSnapshot> _scans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _chronos.loadAllScans();
    setState(() {
      _scans = data..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ISH Zaman Tüneli (Chronos)")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _scans.isEmpty
              ? Center(child: Text("Henüz kayıtlı tarama yok."))
              : Column(
                  children: [
                    // Grafik
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildTrendChart(),
                      ),
                    ),
                    // Liste ve Overlay Karşılaştırma
                    Expanded(
                      flex: 3,
                      child: ListView.builder(
                        itemCount: _scans.length,
                        itemBuilder: (ctx, idx) {
                          final scan = _scans[idx];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: scan.averageFusionScore > 0.6 ? Colors.red : Colors.green,
                                child: Text("${(scan.averageFusionScore * 100).toInt()}%"),
                              ),
                              title: Text(DateFormat('dd MMM yyyy - HH:mm').format(scan.timestamp)),
                              subtitle: Text("Nokta sayısı: ${scan.pointData.length}"),
                              trailing: IconButton(
                                icon: Icon(Icons.compare_arrows),
                                onPressed: () {
                                  if (idx > 0) {
                                    final old = _scans[idx - 1];
                                    final diff = _chronos.compareOverlay(old, scan);
                                    _showOverlayDialog(context, diff);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  // Gerçek Trend Grafiği (charts_flutter)
  Widget _buildTrendChart() {
    final series = [
      charts.Series<Map<String, dynamic>, String>(
        id: 'Sağlık Skoru',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (data, _) => data['date'] as String,
        measureFn: (data, _) => data['score'] as double,
        data: _chronos.getTrendData(_scans),
      )
    ];
    return charts.LineChart(
      series,
      animate: true,
      primaryMeasureAxis: charts.NumericAxisSpec(
        viewport: charts.NumericExtents(0.0, 1.0),
      ),
    );
  }

  void _showOverlayDialog(BuildContext context, List<List<double>> diffGrid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Önceki ile Fark Haritası"),
        content: Container(
          width: 300,
          height: 300,
          color: Colors.black,
          child: CustomPaint(
            painter: DiffHeatmapPainter(diffGrid: diffGrid),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_), child: Text("Kapat")),
        ],
      ),
    );
  }
}

// Fark haritası için özel painter
class DiffHeatmapPainter extends CustomPainter {
  final List<List<double>> diffGrid;
  DiffHeatmapPainter({required this.diffGrid});

  @override
  void paint(Canvas canvas, Size size) {
    double cellW = size.width / 64;
    double cellH = size.height / 64;
    for (int i = 0; i < 64; i++) {
      for (int j = 0; j < 64; j++) {
        double val = diffGrid[i][j];
        int grey = (val * 255).clamp(0, 255).toInt();
        Paint p = Paint()..color = Color.fromARGB(255, grey, 0, 0);
        canvas.drawRect(Rect.fromLTWH(i * cellW, j * cellH, cellW, cellH), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
