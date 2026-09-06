import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/services/analysis/chronos_service.dart';
import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';
import 'package:intl/intl.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

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
    final scans = await _chronos.loadAllScans();
    if (!mounted) return;
    setState(() {
      _scans = scans;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_scans.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Henüz doğrulanmış tarama kaydı yok.')),
      );
    }

    final values = _scans.map((scan) => scan.averageFusionScore).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Chronos Zaman Tüneli')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: _TimelinePainter(
                  values: values,
                  minValue: minValue,
                  maxValue: maxValue,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 12),
            Text('Kayıt sayısı: ${_scans.length}'),
            Text(DateFormat('dd.MM.yyyy HH:mm').format(_scans.last.timestamp)),
          ],
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter({
    required this.values,
    required this.minValue,
    required this.maxValue,
  });

  final List<double> values;
  final double minValue;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    final line = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final grid = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final range = (maxValue - minValue).abs() < 1e-12
        ? 1.0
        : maxValue - minValue;
    final path = Path();

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final normalized = (values[i] - minValue) / range;
      final y = size.height - normalized * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.minValue != minValue ||
      oldDelegate.maxValue != maxValue;
}
