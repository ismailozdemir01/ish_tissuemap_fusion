import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/services/sensor/acoustic_service.dart';
import 'package:ish_tissuemap_fusion/services/sensor/emf_service.dart';
import 'package:ish_tissuemap_fusion/services/sensor/fusion_engine.dart';
import 'package:ish_tissuemap_fusion/models/tissue_point.dart';
import 'package:ish_tissuemap_fusion/widgets/heatmap_painter.dart';
import 'dart:async';

class ScanScreen extends StatefulWidget {
  final String connectionType; // "USB" veya "BLE"
  const ScanScreen({super.key, required this.connectionType});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final FusionEngine _engine = FusionEngine();
  final AcousticService _acoustic = AcousticService();
  final EMFService _emf = EMFService();

  bool _isScanning = false;
  double _posX = 0.5, _posY = 0.5; // Telefonun ekrandaki sanal pozisyonu
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _acoustic.init();
    _emf.startListening((conductivity) {
      if (_isScanning) {
        _captureData(conductivity);
      }
    });
  }

  void _captureData(double conductivity) async {
    // Gerçek zamanlı yoğunluk ölçümü
    double density = await _acoustic.measureDensity();

    final point = TissuePoint(
      x: _posX,
      y: _posY,
      density: density,
      conductivity: conductivity,
      timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );

    setState(() {
      _engine.addSample(point);
    });

    // Telefonun hareketini simüle et (Gerçekte gyro ile güncellenir)
    _posX += (Random().nextDouble() - 0.5) * 0.05;
    _posY += (Random().nextDouble() - 0.5) * 0.05;
    _posX = _posX.clamp(0.0, 1.0);
    _posY = _posY.clamp(0.0, 1.0);
  }

  void _startScan() {
    setState(() { _isScanning = true; });
    _scanTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      // Her 100ms'de bir veri topla
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ISH Tarama - ${widget.connectionType}")),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: CustomPaint(
                painter: HeatmapPainter(engine: _engine),
                size: Size.infinite,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isScanning ? null : _startScan,
                child: Text("Tarama Başlat"),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () { setState(() { _engine.clear(); }); },
                child: Text("Temizle"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
          Text("Toplam Örnek: ${_engine.points.length}", style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }
}
