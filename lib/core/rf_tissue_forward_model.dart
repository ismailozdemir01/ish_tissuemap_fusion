import 'dart:math' as math;

import 'tissue_volume_reconstruction_engine.dart';

/// Frequency-dependent calibration supplied by measured phantom/human-data
/// validation. No tissue constants are embedded in production code.
abstract class RfTissueCalibration {
  String get calibrationId;
  bool get validated;

  /// Sensitivity of one voxel property unit at the supplied frequency.
  double sensitivity(double frequencyMHz);

  /// Effective attenuation coefficient for the calibrated medium.
  double attenuationNpPerMeter(double frequencyMHz);
}

/// Software forward operator for the phone-only RF inverse problem.
///
/// The operator maps a voxel property contrast to a predicted measurement
/// residual. Geometry comes from the phone trajectory; material response comes
/// only from an explicitly supplied calibration object.
class PhoneRfTissueForwardModel implements ValidatedTissueForwardModel {
  @override
  final String modelId;
  final RfTissueCalibration calibration;
  final double minimumDistanceMeters;
  final double pathLengthScale;
  @override
  final int voxelCount;

  const PhoneRfTissueForwardModel({
    required this.modelId,
    required this.calibration,
    required this.voxelCount,
    this.minimumDistanceMeters = 0.01,
    this.pathLengthScale = 1.0,
  });

  @override
  bool get validated => calibration.validated;

  @override
  List<List<double>> buildForwardMatrix({
    required List<double> frequenciesMHz,
    required List<List<double>> voxelCoordinates,
    required List<List<double>> measurementCoordinates,
  }) {
    if (voxelCoordinates.length != voxelCount ||
        frequenciesMHz.length != measurementCoordinates.length ||
        voxelCoordinates.any((v) => v.length != 3) ||
        measurementCoordinates.any((v) => v.length != 3)) {
      throw ArgumentError('Incompatible RF forward-model geometry');
    }

    final matrix = <List<double>>[];
    for (var m = 0; m < measurementCoordinates.length; m++) {
      final frequency = frequenciesMHz[m];
      if (!frequency.isFinite || frequency <= 0) {
        throw ArgumentError('Invalid RF frequency');
      }
      final sensitivity = calibration.sensitivity(frequency);
      final attenuation = calibration.attenuationNpPerMeter(frequency);
      if (!sensitivity.isFinite || !attenuation.isFinite || attenuation < 0) {
        throw ArgumentError('Invalid RF calibration response');
      }

      final source = measurementCoordinates[m];
      final row = <double>[];
      for (final voxel in voxelCoordinates) {
        final dx = voxel[0] - source[0];
        final dy = voxel[1] - source[1];
        final dz = voxel[2] - source[2];
        final distance = math.max(minimumDistanceMeters,
            math.sqrt(dx * dx + dy * dy + dz * dz));
        final path = distance * pathLengthScale;
        final geometric = 1.0 / distance;
        final medium = math.exp(-attenuation * path);
        final value = sensitivity * geometric * medium;
        if (!value.isFinite) {
          throw StateError('Non-finite RF forward coefficient');
        }
        row.add(value);
      }
      matrix.add(row);
    }
    return matrix;
  }
}
