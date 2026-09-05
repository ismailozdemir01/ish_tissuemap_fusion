import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/services/sensor/ar_guidance_service.dart';
import 'package:ish_tissuemap_fusion/services/sensor/fusion_engine.dart';
import 'package:ish_tissuemap_fusion/services/sensor/acoustic_service.dart';
import 'package:ish_tissuemap_fusion/services/sensor/emf_service.dart';
import 'package:ish_tissuemap_fusion/services/processing/motion_cancellation_service.dart';
import 'package:ish_tissuemap_fusion/services/analysis/chronos_service.dart';
import 'package:ish_tissuemap_fusion/models/tissue_point.dart';
import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';
import 'package:ish_tissuemap_fusion/models/anomaly_report.dart';
import 'package:ish_tissuemap_fusion/widgets/heatmap_painter.dart';
import 'package:ish_tissuemap_fusion/widgets/ar_overlay_painter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class ARScanScreen extends StatefulWidget {
  final String connectionType;
  const ARScanScreen({super.key, required this.connectionType});

  @override
  State<ARScanScreen> createState() => _ARScanScreenState();
}

class _ARScanScreenState extends State<ARScanScreen> {
  final FusionEngine _engine = FusionEngine();
  final AcousticService _acoustic = AcousticService();
  final EMFService _emf = EMFService();
  final MotionCancellationService _mac = MotionCancellationService();
  final ChronosService _chronos = ChronosService();
  final ARGuidanceService _ar = ARGuidanceService();

  bool _isScanning = false;
  double _posX = 0.5, _posY = 0.5;
  Timer? _scanTimer;
  List<TissuePoint> _currentSessionPoints = [];
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _acoustic.init();
    _ar.initCamera();
    
    // EMF dinlemeye başla
    _emf.startListening((rawConductivity) {
      if (_isScanning) {
        // 1. Hareket verisini al (ivmeölçer + jiroskop)
        accelerometerEvents.listen((acc) {
          gyroscopeEvents.listen((gyro) {
            // 2. Kalman Filtresinden geçir (MAC)
            double filteredConductivity = _mac.correct(rawConductivity, acc, gyro);
            _confidence = _mac.getConfidenceScore();
            // 3. Veriyi yakala
            _captureData(filteredConductivity);
          });
        });
      }
    });
  }

  void _captureData(double filteredConductivity) async {
    // Akustik yoğunluğu ölç (MAC uygulanmış hali)
    double rawDensity = await _acoustic.measureDensity();
    // Akustik için de ayrı bir Kalman uygulanabilir, kısaca direk kullanalım.
    // AR'den tahmini konumu al
    final estimatedPos = _ar.estimatePositionOnBody();
    setState(() {
      _posX = estimatedPos.x;
      _posY = estimatedPos.y;
    });

    final point = TissuePoint(
      x: _posX,
      y: _posY,
      density: rawDensity.clamp(0.0, 1.0),
      conductivity: filteredConductivity,
      timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );
    
    setState(() {
      _engine.addSample(point);
      _currentSessionPoints.add(point);
    });
  }

  void _startScan() {
    setState(() { _isScanning = true; });
    _scanTimer = Timer.periodic(Duration(milliseconds: 150), (timer) {
      // Zaten EMF tetikliyor, sadece timer senkronu
    });
  }

  void _stopAndSaveScan() async {
    setState(() { _isScanning = false; });
    _scanTimer?.cancel();

    // Raport oluştur
    final report = AnomalyReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      findings: _engine.points.where((p) => p.fusionScore > 0.7).map((p) => "Anomali bölgesi: (${p.x.toStringAsFixed(2)}, ${p.y.toStringAsFixed(2)})").toList(),
    );

    final avgScore = _engine.points.fold(0.0, (s, p) => s + p.fusionScore) / _engine.points.length;

    // Chronos'a kaydet
    final snapshot = ChronosSnapshot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      pointData: _engine.points.map((p) => p.toJson()).toList(),
      report: report,
      averageFusionScore: avgScore,
    );
    await _chronos.saveCurrentScan(snapshot);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Tarama kaydedildi! Genel skor: ${avgScore.toStringAsFixed(2)}"),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ISH AR Tarama - ${widget.connectionType}"),
        actions: [
          IconButton(
            icon: Icon(Icons.timeline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TimelineScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. KATMAN: Kamera (AR Arka Plan)
          if (_ar.isReady)
            CameraPreview(_ar.controller!)
          else
            Container(color: Colors.black, child: Center(child: CircularProgressIndicator())),

          // 2. KATMAN: Isı Haritası (Yarı Saydam)
          Container(
            margin: EdgeInsets.all(10),
            child: CustomPaint(
              painter: HeatmapPainter(engine: _engine, opacity: 0.5),
              size: Size.infinite,
            ),
          ),

          // 3. KATMAN: AR Overlay (Vücut Şablonu ve Etiketler)
          CustomPaint(
            painter: AROverlayPainter(
              estimatedPosition: _ar.estimatePositionOnBody(),
              isScanning: _isScanning,
            ),
            size: Size.infinite,
          ),

          // 4. KATMAN: Alt Kontroller
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: Icon(Icons.play_arrow),
                  label: Text("Tarama Başlat"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _isScanning ? _stopAndSaveScan : null,
                  icon: Icon(Icons.stop),
                  label: Text("Durdur & Kaydet"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () => setState(() { _engine.clear(); _currentSessionPoints.clear(); }),
                  icon: Icon(Icons.delete_forever),
                  label: Text("Temizle"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
              ],
            ),
          ),
          // Güven İndeksi göster
          Positioned(
            top: 20, right: 20,
            child: Container(
              color: Colors.black54,
              padding: EdgeInsets.all(8),
              child: Text("MAC Güven: ${(_confidence * 100).toInt()}%", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _ar.dispose();
    super.dispose();
  }
}
