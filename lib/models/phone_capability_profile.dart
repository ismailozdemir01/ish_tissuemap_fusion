import 'imaging_pipeline.dart';
import '../core/sensor_capability.dart';
import 'rf_measurement.dart';

/// Runtime capability snapshot. It describes what the current handset exposes,
/// not what the application wishes it exposed.
class PhoneCapabilityProfile {
  final String platform;
  final String? operatingSystemVersion;
  final List<SensorCapability> sensors;
  final Set<SignalModality> availableModalities;
  final RfAccessLevel rfAccessLevel;
  final bool cameraAvailable;

  const PhoneCapabilityProfile({
    required this.platform,
    required this.operatingSystemVersion,
    required this.sensors,
    required this.availableModalities,
    required this.rfAccessLevel,
    required this.cameraAvailable,
  });

  bool supports(SignalModality modality) => availableModalities.contains(modality);

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'operatingSystemVersion': operatingSystemVersion,
        'sensors': sensors.map((s) => {
              'id': s.id,
              'name': s.name,
              'modality': s.modality.name,
              'availability': s.availability.name,
              'nominalSampleRateHz': s.nominalSampleRateHz,
              'units': s.units,
            }).toList(),
        'availableModalities': availableModalities.map((m) => m.name).toList(),
        'rfAccessLevel': rfAccessLevel.name,
        'cameraAvailable': cameraAvailable,
      };
}
