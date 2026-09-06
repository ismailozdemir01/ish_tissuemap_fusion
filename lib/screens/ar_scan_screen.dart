import 'dart:async';
import 'package:camera/camera.dart';
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
import 'package:ish_tissuemap_fusion/screens/timeline_screen.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  final List<TissuePoint> _currentSessionPoints = [];
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _acoustic.init();
    _ar.initCamera();
    _emf.startListening((rawFieldMagnitude) {
      if (_isScanning) {
        accelerometerEvents.first.then((acc) {
          gyroscopeEvents.first.then((gyro) {
            final filtered = _mac.correct(rawFieldMagnitude, acc, gyro);
            _confidence = _mac.getConfidenceScore();
            _captureData(filtered);
          });
        });
      }
    });
  }

  Future<void> _captureData(double filteredFieldMagnitude) async {
    // Current phone sensors do not provide a validated tissue-density measurement.
    // Do not convert magnetic field strength into a fabricated clinical value.
    final estimatedPos = _ar.estimatePositionOnBody();
    if (!mounted) return;
    setState(() {
      _posX = estimatedPos.x;
      _posY = estimatedPos.y;
    });
  }

  void _startScan() => setState(() => _isScanning = true);

  Future<void> _stopAndSaveScan() async {
    setState(() => _isScanning = false);
    _scanTimer?.cancel();
    if (_engine.points.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doğrulanmış doku ölçümü bulunmadığı için kayıt oluşturulmadı.')),
        );
      }
      return;
    }

    final report = AnomalyReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      findings: _engine.points
          .where((p) => p.fusionScore > 0.7)
          .map((p) => 'Anomali bölgesi: (${p.x.toStringAsFixed(2)}, ${p.y.toStringAsFixed(2)})')
          .toList(),
    );
    final avgScore = _engine.points.fold<double>(0, (s, p) => s + p.fusionScore) / _engine.points.length;
    final snapshot = ChronosSnapshot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      pointData: _engine.points.map((p) => p.toJson()).toList(),
      report: report,
      averageFusionScore: avgScore,
    );
    await _chronos.saveCurrentScan(snapshot);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('ISH Tarama - ${widget.connectionType}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.timeline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimelineScreen()),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_ar.isReady)
              CameraPreview(_ar.controller!)
            else
              const ColoredBox(
                color: Colors.black,
                child: Center(child: CircularProgressIndicator()),
              ),
            Container(
              margin: const EdgeInsets.all(10),
              child: CustomPaint(
                painter: HeatmapPainter(engine: _engine, opacity: 0.5),
                size: Size.infinite,
              ),
            ),
            CustomPaint(
              painter: AROverlayPainter(
                estimatedPosition: _ar.estimatePositionOnBody(),
                isScanning: _isScanning,
              ),
              size: Size.infinite,
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _startScan,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Tarama Başlat'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _isScanning ? _stopAndSaveScan : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Durdur'),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(8),
                child: Text(
                  'MAC Güven: ${(_confidence * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _scanTimer?.cancel();
    _emf.dispose();
    _ar.dispose();
    super.dispose();
  }
}
