import 'dart:convert';

import '../core/rf_tissue_forward_model.dart';

/// A runtime RF calibration profile backed by externally measured validation
/// evidence. Production code never invents tissue parameters or reference
/// measurements; the profile must be supplied by a real calibration process.
class RfCalibrationProfile implements RfTissueCalibration {
  @override
  final String calibrationId;
  final String deviceProfileId;
  final String validationDatasetId;
  final String validationEvidenceHash;
  @override
  final bool validated;
  final Map<double, double> referenceRssiDbmByFrequency;
  final Map<double, double> sensitivityByFrequency;
  final Map<double, double> attenuationNpPerMeterByFrequency;

  const RfCalibrationProfile({
    required this.calibrationId,
    required this.deviceProfileId,
    required this.validationDatasetId,
    required this.validationEvidenceHash,
    required this.validated,
    required this.referenceRssiDbmByFrequency,
    required this.sensitivityByFrequency,
    required this.attenuationNpPerMeterByFrequency,
  });

  double _lookup(Map<double, double> values, double frequencyMHz) {
    final value = values[frequencyMHz];
    if (value != null) return value;
    for (final entry in values.entries) {
      if ((entry.key - frequencyMHz).abs() < 0.001) return entry.value;
    }
    return double.nan;
  }

  @override
  double sensitivity(double frequencyMHz) =>
      _lookup(sensitivityByFrequency, frequencyMHz);

  @override
  double attenuationNpPerMeter(double frequencyMHz) =>
      _lookup(attenuationNpPerMeterByFrequency, frequencyMHz);

  @override
  double? referenceRssiDbm(double frequencyMHz) =>
      _lookup(referenceRssiDbmByFrequency, frequencyMHz).isFinite
          ? _lookup(referenceRssiDbmByFrequency, frequencyMHz)
          : null;

  Map<String, dynamic> toJson() => {
        'calibrationId': calibrationId,
        'deviceProfileId': deviceProfileId,
        'validationDatasetId': validationDatasetId,
        'validationEvidenceHash': validationEvidenceHash,
        'validated': validated,
        'referenceRssiDbmByFrequency': referenceRssiDbmByFrequency
            .map((key, value) => MapEntry(key.toString(), value)),
        'sensitivityByFrequency': sensitivityByFrequency
            .map((key, value) => MapEntry(key.toString(), value)),
        'attenuationNpPerMeterByFrequency': attenuationNpPerMeterByFrequency
            .map((key, value) => MapEntry(key.toString(), value)),
      };

  String encode() => jsonEncode(toJson());

  factory RfCalibrationProfile.fromJson(Map<String, dynamic> json) {
    Map<double, double> readMap(String key) {
      final raw = json[key];
      if (raw is! Map) return const {};
      final result = <double, double>{};
      raw.forEach((key, value) {
        final frequency = double.tryParse(key.toString());
        final number = value is num ? value.toDouble() : double.tryParse(value.toString());
        if (frequency != null && number != null && frequency > 0 && number.isFinite) {
          result[frequency] = number;
        }
      });
      return result;
    }

    return RfCalibrationProfile(
      calibrationId: json['calibrationId']?.toString() ?? '',
      deviceProfileId: json['deviceProfileId']?.toString() ?? '',
      validationDatasetId: json['validationDatasetId']?.toString() ?? '',
      validationEvidenceHash: json['validationEvidenceHash']?.toString() ?? '',
      validated: json['validated'] == true,
      referenceRssiDbmByFrequency: readMap('referenceRssiDbmByFrequency'),
      sensitivityByFrequency: readMap('sensitivityByFrequency'),
      attenuationNpPerMeterByFrequency: readMap('attenuationNpPerMeterByFrequency'),
    );
  }

  factory RfCalibrationProfile.decode(String source) =>
      RfCalibrationProfile.fromJson(jsonDecode(source) as Map<String, dynamic>);

  bool get hasValidationEvidence =>
      calibrationId.isNotEmpty &&
      deviceProfileId.isNotEmpty &&
      validationDatasetId.isNotEmpty &&
      validationEvidenceHash.isNotEmpty;
}
