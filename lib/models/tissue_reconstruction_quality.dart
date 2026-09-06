import 'measurement_status.dart';

class TissueReconstructionQuality {
  final int measurementCount;
  final int uniqueFrequencyCount;
  final int voxelCount;
  final double residualNorm;
  final double residualRms;
  final double conditionEstimate;
  final double meanUncertainty;
  final MeasurementStatus status;
  final String reason;

  const TissueReconstructionQuality({
    required this.measurementCount,
    required this.uniqueFrequencyCount,
    required this.voxelCount,
    required this.residualNorm,
    required this.residualRms,
    required this.conditionEstimate,
    required this.meanUncertainty,
    required this.status,
    required this.reason,
  });

  static TissueReconstructionQuality unknown({String reason = 'QUALITY_NOT_AVAILABLE'}) =>
      TissueReconstructionQuality(
        measurementCount: 0,
        uniqueFrequencyCount: 0,
        voxelCount: 0,
        residualNorm: double.infinity,
        residualRms: double.infinity,
        conditionEstimate: double.infinity,
        meanUncertainty: double.infinity,
        status: MeasurementStatus.unknown,
        reason: reason,
      );
}
