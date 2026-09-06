import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/services/sensor/ar_guidance_service.dart';
import 'package:ish_tissuemap_fusion/services/sensor/fusion_engine.dart';
import 'package:ish_tissuemap_fusion/services/sensor/emf_service.dart';
import 'package:ish_tissuemap_fusion/services/processing/motion_cancellation_service.dart';
import 'package:ish_tissuemap_fusion/services/analysis/chronos_service.dart';
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
  final EMFService _emf = EMFService();
  final MotionCancellationService _mac = MotionCancellationService();
  final ChronosService _chronos = ChronosService();
  final ARGuidanceService _ar = ARGuidanceService();

  bool _isScanning = false;
  Timer? _scanTimer;
  double _confidence = 0;
  double _fieldMagnitude = 0;

  @override
  void initState() {
    super.initState();
    _ar.initCamera();
    _emf.startListening((rawFieldMagnitude) {
      if (!_isScanning || !mounted) return;
      accelerometerEvents.first.then((acc) {
        if (!mounted || !_isScanning) return;
        gyroscopeEvents.first.then((gyro) {
          if (!mounted || !_isScanning) return;
          final filtered = _mac.correct(rawFieldMagnitude, acc, gyro);
          if (mounted) {
            setState(() {
              _fieldMagnitude = filtered;
              _confidence = _mac.getConfidenceScore();
            });
          }
        });
      });
    });
  }

  void _startScan() => setState(() => _isScanning = true);

  Future<void> _stopAndSaveScan() async {
    setState(() => _isScanning = false);
    _scanTimer?.cancel();
    if (_engine.points.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telefon sensörleri yalnızca ham telemetri sağlıyor; doğrulanmış doku ölçümü kaydedilmedi.'),
        ),
      );
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
    await _chronos.saveCurrentScan(ChronosSnapshot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      pointData: _engine.points.map((p) => p.toJson()).toList(),
      report: report,
      averageFusionScore: avgScore,
    ));
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
                MaterialPageRoute(builder: (_) => TimelineScreen()),
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
            CustomPaint(
              painter: HeatmapPainter(engine: _engine, opacity: 0.5),
              size: Size.infinite,
            ),
            CustomPaint(
              painter: AROverlayPainter(
                estimatedPosition: _ar.estimatePositionOnBody(),
                isScanning: _isScanning,
              ),
              size: Size.infinite,
            ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Ham manyetik alan: ${_fieldMagnitude.toStringAsFixed(2)} µT\n'
                    'Sinyal güveni: ${(_confidence * 100).toStringAsFixed(0)}%\n'
                    'Klinik doku ölçümü: UNKNOWN',
                  ),
                ),
              ),
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
