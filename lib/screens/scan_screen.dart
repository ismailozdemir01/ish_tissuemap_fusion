import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/services/sensor/emf_service.dart';

class ScanScreen extends StatefulWidget {
  final String connectionType;
  const ScanScreen({super.key, required this.connectionType});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final EMFService _emf = EMFService();
  bool _isScanning = false;
  double _fieldMagnitude = 0;

  @override
  void initState() {
    super.initState();
    _emf.startListening((value) {
      if (mounted && _isScanning) setState(() => _fieldMagnitude = value);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('ISH Sensör Tanılama - ${widget.connectionType}')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sensors, size: 72),
                const SizedBox(height: 24),
                Text('Manyetik alan: ${_fieldMagnitude.toStringAsFixed(2)} µT',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 12),
                const Text(
                  'Bu değer ham telefon sensör telemetrisidir. Klinik doku yoğunluğu veya iletkenliği olarak yorumlanmaz.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => setState(() => _isScanning = !_isScanning),
                  child: Text(_isScanning ? 'Durdur' : 'Sensörleri Başlat'),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _emf.dispose();
    super.dispose();
  }
}
