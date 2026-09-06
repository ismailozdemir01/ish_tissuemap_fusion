import 'medical_device_adapter.dart';

class MedicalDeviceRegistry {
  final Map<String, MedicalDeviceAdapter> _adapters = {};

  void register(MedicalDeviceAdapter adapter) {
    _adapters[adapter.adapterId] = adapter;
  }

  MedicalDeviceAdapter? find(String adapterId) => _adapters[adapterId];

  List<MedicalDeviceAdapter> get adapters => List.unmodifiable(_adapters.values);

  Future<void> disconnectAll() async {
    for (final adapter in _adapters.values) {
      if (adapter.isConnected) await adapter.disconnect();
    }
  }
}
