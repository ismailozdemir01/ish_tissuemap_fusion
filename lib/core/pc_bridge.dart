import '../models/imaging_pipeline.dart';

enum PcTransport { bluetooth, wifi, usb }

class PcBridgeStatus {
  final PcTransport transport;
  final bool connected;
  final String? endpoint;

  const PcBridgeStatus({required this.transport, required this.connected, this.endpoint});
}

abstract interface class PcProcessingBridge {
  PcTransport get transport;
  Future<void> connect();
  Future<void> disconnect();
  Future<void> sendRawSamples(List<RawSignalSample> samples);
  Stream<RawSignalSample> receiveProcessedSamples();
  bool get connected;
}

class HybridProcessingController {
  ProcessingLocation location = ProcessingLocation.phone;
  PcProcessingBridge? bridge;

  Future<void> enablePcOffload(PcProcessingBridge pcBridge) async {
    bridge = pcBridge;
    await pcBridge.connect();
    if (pcBridge.connected) location = ProcessingLocation.hybrid;
  }

  Future<void> disablePcOffload() async {
    final current = bridge;
    bridge = null;
    location = ProcessingLocation.phone;
    if (current != null) await current.disconnect();
  }

  Future<void> route(List<RawSignalSample> samples) async {
    final current = bridge;
    if (location == ProcessingLocation.hybrid && current?.connected == true) {
      await current!.sendRawSamples(samples);
    }
  }
}
