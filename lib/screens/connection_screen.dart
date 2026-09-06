import 'package:flutter/material.dart';
import 'ar_scan_screen.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  void _openPhoneMode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ARScanScreen(connectionType: 'PHONE')),
    );
  }

  void _showUnavailable(BuildContext context, String mode) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$mode modu'),
        content: const Text(
          'Bu mod için gerçek cihaz adaptörü ve cihaz protokolü yapılandırılmadan bağlantı kurulmaz. '
          'Sistem sahte bağlantı/ölçüm üretmez.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ISH TissueMap Fusion')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.health_and_safety, size: 84),
            const SizedBox(height: 16),
            const Text(
              'Veri Kaynağı Seçimi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Telefon, doğrulanmış tıbbi cihaz veya hibrit kaynak kullanılabilir. '
              'Doğrulanmamış klinik ölçüm üretilemez.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _modeButton(context, 'Telefon sensörleri', Icons.smartphone,
                () => _openPhoneMode(context)),
            _modeButton(context, 'Tıbbi cihaz', Icons.medical_services,
                () => _showUnavailable(context, 'Tıbbi cihaz')),
            _modeButton(context, 'Hibrit', Icons.merge_type,
                () => _showUnavailable(context, 'Hibrit')),
          ],
        ),
      );

  Widget _modeButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          height: 60,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(title, style: const TextStyle(fontSize: 17)),
          ),
        ),
      );
}
