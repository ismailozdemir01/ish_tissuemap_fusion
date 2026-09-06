import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/services/sensor/acoustic_service.dart';
import 'package:ish_tissuemap_fusion/services/sensor/emf_service.dart';
import 'package:ish_tissuemap_fusion/services/sensor/fusion_engine.dart';
import 'package:ish_tissuemap_fusion/models/tissue_point.dart';
import 'package:ish_tissuemap_fusion/widgets/heatmap_painter.dart';

class ScanScreen extends StatefulWidget {
  final String connectionType;
  const ScanScreen({super.key, required this.connectionType});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final FusionEngine _engine = FusionEngine();
  final AcousticService _acoustic = AcousticService();
  final EMFService _emf = EMFService();

  bool _isScanning = false;
  double _posX = 0.5, _posY = 0.5;
  Timer? _scanTimer;
  final Random _random = Random();

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

    // Gerçek gyro verisi gelene kadar random ile pozisyon değiştir (simülasyon değil, test için)
    _posX += (_random.nextDouble() - 0.5) * 0.05;
    _posY += (_random.nextDouble() - 0.5) * 0.05;
    _posX = _posX.clamp(0.0, 1.0);
    _posY = _posY.clamp(0.0, 1.0);
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
    });
    _scanTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Sadece UI'ı yenilemek için, veri zaten EMF listener'dan geliyor.
    });
  }

  void _stopScan() {
    setState(() {
      _isScanning = false;
    });
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ISH Tarama - ${widget.connectionType}")),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
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
                child: const Text("Tarama Başlat"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _isScanning ? _stopScan : null,
                child: const Text("Durdur"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _engine.clear();
                  });
                },
                child: const Text("Temizle"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
            ],
          ),
          Text("Toplam Örnek: ${_engine.points.length}",
              style: const TextStyle(fontSize: 18)),
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
