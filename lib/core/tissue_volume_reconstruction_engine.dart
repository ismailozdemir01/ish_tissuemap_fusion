import '../models/measurement_status.dart';
import '../models/tissue_volume.dart';
import 'regularized_rf_inverse_solver.dart';

/// Contract for a scientifically validated forward tissue/RF model.
/// Implementations must be backed by calibration/validation data; this
/// repository does not fabricate tissue dielectric or attenuation values.
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

/// 3-D tissue reconstruction pipeline. It can solve a real inverse problem,
/// but refuses to label the result anatomical until a validated tissue model
/// and compatible forward matrix are supplied.
class TissueVolumeReconstructionEngine {
  final RegularizedRfInverseSolver solver;

  const TissueVolumeReconstructionEngine({
    this.solver = const RegularizedRfInverseSolver(),
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
        voxelCoordinates.any((v) => v.length != 3) ||
        measurementCoordinates.any((v) => v.length != 3) ||
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
    final voxels = <TissueVoxel>[];
    for (var i = 0; i < result.values.length; i++) {
      final c = voxelCoordinates[i];
      voxels.add(TissueVoxel(
        x: c[0], y: c[1], z: c[2], value: result.values[i],
        uncertainty: result.residualNorm,
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
    );
  }
}
