import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/services/analysis/chronos_service.dart';
import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';
import 'package:charts_flutter_maintained/charts_flutter_maintained.dart' as charts;
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
    final scans = await _chronos.loadAllScans();
    if (!mounted) return;
    setState(() {
      _scans = scans;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_scans.isEmpty) {
      return const Scaffold(body: Center(child: Text('Henüz doğrulanmış tarama kaydı yok.')));
    }

    final series = [
      charts.Series<ChronosSnapshot, DateTime>(
        id: 'FusionScore',
        domainFn: (s, _) => s.timestamp,
        measureFn: (s, _) => s.averageFusionScore,
        data: _scans,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Chronos Zaman Tüneli')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: charts.TimeSeriesChart(
                series,
                animate: false,
                dateTimeFactory: const charts.LocalDateTimeFactory(),
              ),
            ),
            Text('Kayıt sayısı: ${_scans.length}'),
            Text(DateFormat('dd.MM.yyyy HH:mm').format(_scans.last.timestamp)),
          ],
        ),
      ),
    );
  }
}
