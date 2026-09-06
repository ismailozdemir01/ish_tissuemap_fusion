import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/screens/ar_scan_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _isConnecting = false;

  void _connect(String type) {
    setState(() => _isConnecting = true);
    // Gerçek bağlantı simülasyonu değil, doğrudan geçiş yapıyoruz.
    // Burada gerçek USB/BLE bağlantı kodları çağrılabilir.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ARScanScreen(connectionType: type)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF0A0E17), const Color(0xFF1A2233)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                'ISH TissueMap Fusion',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'Vücut Tarama ve Sağlık Asistanı',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 60),
              _buildConnectButton('USB Bağlan', Icons.usb, () => _connect('USB')),
              const SizedBox(height: 20),
              _buildConnectButton('Bluetooth Bağlan', Icons.bluetooth, () => _connect('BLE')),
              const SizedBox(height: 40),
              if (_isConnecting) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectButton(String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
