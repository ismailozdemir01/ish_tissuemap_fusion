import '../../models/measurement_result.dart';

enum MedicalTransport { ble, usb, network }

abstract interface class MedicalDeviceAdapter {
  String get adapterId;
  MedicalTransport get transport;

  Future<bool> connect();
  Future<void> disconnect();
  Stream<MeasurementResult> measurements();

  bool get isConnected;
}
