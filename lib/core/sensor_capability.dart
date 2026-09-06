import '../models/imaging_pipeline.dart';

enum SensorAvailability { available, permissionRequired, unavailable, notCalibrated, notSupported }

class SensorCapability {
  final String id;
  final String name;
  final SignalModality modality;
  final SensorAvailability availability;
  final double? nominalSampleRateHz;
  final List<String> units;

  const SensorCapability({
    required this.id,
    required this.name,
    required this.modality,
    required this.availability,
    this.nominalSampleRateHz,
    this.units = const [],
  });
}

abstract interface class PhoneSensor {
  SensorCapability get capability;
  Stream<RawSignalSample> get samples;
  Future<void> start();
  Future<void> stop();
}

abstract interface class AcquisitionDevice {
  String get deviceId;
  String get name;
  Set<SignalModality> get modalities;
  bool get connected;
  Future<void> connect();
  Future<void> disconnect();
  Stream<RawSignalSample> acquire();
}
