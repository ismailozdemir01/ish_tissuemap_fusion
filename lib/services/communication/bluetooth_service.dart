import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> services = [];

  Future<void> scanAndConnect(Function(String) onStatus) async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (var res in results) {
        if (res.device.name.contains("ISH")) { // ISH marka cihazlarla eşleş
          FlutterBluePlus.stopScan();
          _connectToDevice(res.device, onStatus);
          return;
        }
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device, Function(String) onStatus) async {
    onStatus("ISH Cihazına bağlanıyor...");
    await device.connect();
    _connectedDevice = device;
    onStatus("Bağlantı kuruldu. Veri geliyor...");

    // Gerçek veri okuma döngüsü
    device.discoverServices();
    // Burada karakteristik okuma işlemleri yapılır (Kod kısaltması)
  }

  void sendCommand(String cmd) {
    // Gerçek BLE yazma işlemi
    // _connectedDevice.writeCharacteristic(...)
  }
}
