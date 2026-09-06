import 'dart:math' as math;

import '../models/measurement_status.dart';
import '../models/tissue_reconstruction_quality.dart';
import '../models/tissue_volume.dart';
import 'regularized_rf_inverse_solver.dart';

abstract class ValidatedTissueForwardModel {
  String get modelId;
  bool get validated;
  int get voxelCount;

  List<List<double>> buildForwardMatrix({
    required List<double> frequenciesMHz,
    required List<List<double>> voxelCoordinates,
    required List<List<double>> measurementCoordinates,
  });
}

class TissueVolumeReconstructionEngine {
  final RegularizedRfInverseSolver solver;
  final double maximumConditionEstimate;

  const TissueVolumeReconstructionEngine({
    this.solver = const RegularizedRfInverseSolver(),
    this.maximumConditionEstimate = 1e8,
  });

  TissueVolume3D reconstruct({
    required ValidatedTissueForwardModel model,
    required List<double> frequenciesMHz,
    required List<List<double>> voxelCoordinates,
    required List<List<double>> measurementCoordinates,
    required List<double> observations,
    List<double>? weights,
    int width = 0,
    int height = 0,
    int depth = 0,
  }) {
    if (!model.validated) {
      return TissueVolume3D.unknown(reason: 'TISSUE_FORWARD_MODEL_NOT_VALIDATED');
    }
    if (voxelCoordinates.length != model.voxelCount ||
        voxelCoordinates.any((v) => v.length != 3 || v.any((x) => !x.isFinite)) ||
        measurementCoordinates.any((v) => v.length != 3 || v.any((x) => !x.isFinite)) ||
        frequenciesMHz.length != measurementCoordinates.length ||
        frequenciesMHz.any((f) => !f.isFinite || f <= 0) ||
        observations.length != measurementCoordinates.length ||
        observations.isEmpty) {
      return TissueVolume3D.unknown(reason: 'INSUFFICIENT_3D_RECONSTRUCTION_GEOMETRY');
    }

    final matrix = model.buildForwardMatrix(
      frequenciesMHz: frequenciesMHz,
      voxelCoordinates: voxelCoordinates,
      measurementCoordinates: measurementCoordinates,
    );
    final result = solver.solve(
      forwardMatrix: matrix,
      observations: observations,
      weights: weights,
    );
    if (!result.valid || result.values.length != voxelCoordinates.length) {
      return TissueVolume3D.unknown(reason: result.reason);
    }
    if (!result.conditionEstimate.isFinite ||
        result.conditionEstimate > maximumConditionEstimate) {
      return TissueVolume3D.unknown(reason: 'INVERSE_SYSTEM_ILL_CONDITIONED');
    }

    final residualRms = result.residualNorm / math.sqrt(observations.length);
    final meanUncertainty = result.residualNorm /
        math.sqrt(math.max(1, result.values.length));
    final uniqueFrequencies = frequenciesMHz.toSet().length;
    final quality = TissueReconstructionQuality(
      measurementCount: observations.length,
      uniqueFrequencyCount: uniqueFrequencies,
      voxelCount: result.values.length,
      residualNorm: result.residualNorm,
      residualRms: residualRms,
      conditionEstimate: result.conditionEstimate,
      meanUncertainty: meanUncertainty,
      status: MeasurementStatus.valid,
      reason: 'INVERSE_QUALITY_ACCEPTED',
    );

    final voxels = <TissueVoxel>[];
    for (var i = 0; i < result.values.length; i++) {
      final c = voxelCoordinates[i];
      voxels.add(TissueVoxel(
        x: c[0],
        y: c[1],
        z: c[2],
        value: result.values[i],
        uncertainty: meanUncertainty,
      ));
    }
    return TissueVolume3D(
      width: width,
      height: height,
      depth: depth,
      voxels: voxels,
      status: MeasurementStatus.valid,
      anatomical: true,
      modelId: model.modelId,
      reason: 'VALIDATED_3D_TISSUE_RECONSTRUCTION',
      quality: quality,
    );
  }
}
