import 'package:flutter_test/flutter_test.dart';

import 'package:ish_tissuemap_fusion/core/regularized_rf_inverse_solver.dart';
import 'package:ish_tissuemap_fusion/core/tissue_volume_reconstruction_engine.dart';

class UnvalidatedModel implements ValidatedTissueForwardModel {
  @override String get modelId => 'test-unvalidated';
  @override bool get validated => false;
  @override int get voxelCount => 1;
  @override List<List<double>> buildForwardMatrix({required List<double> frequenciesMHz, required List<List<double>> voxelCoordinates, required List<List<double>> measurementCoordinates}) => [[1.0]];
}

class ValidatedModel implements ValidatedTissueForwardModel {
  @override String get modelId => 'test-validated';
  @override bool get validated => true;
  @override int get voxelCount => 1;
  @override List<List<double>> buildForwardMatrix({required List<double> frequenciesMHz, required List<List<double>> voxelCoordinates, required List<List<double>> measurementCoordinates}) => [[1.0]];
}

void main() {
  test('inverse solver recovers regularized scalar field', () {
    final result = const RegularizedRfInverseSolver(lambda: 0.01).solve(
      forwardMatrix: [[1.0]], observations: [2.0]);
    expect(result.valid, isTrue);
    expect(result.values.single, closeTo(2.0 / 1.01, 1e-9));
  });

  test('unvalidated tissue model never produces anatomical volume', () {
    final result = const TissueVolumeReconstructionEngine().reconstruct(
      model: UnvalidatedModel(),
      frequenciesMHz: [2412],
      voxelCoordinates: [[0, 0, 0]],
      measurementCoordinates: [[0, 0, 0]],
      observations: [-50],
      width: 1, height: 1, depth: 1,
    );
    expect(result.anatomical, isFalse);
    expect(result.status.name, 'unknown');
  });

  test('validated forward model reaches 3D voxel container', () {
    final result = const TissueVolumeReconstructionEngine().reconstruct(
      model: ValidatedModel(),
      frequenciesMHz: [2412],
      voxelCoordinates: [[0, 0, 0]],
      measurementCoordinates: [[0, 0, 0]],
      observations: [2],
      width: 1, height: 1, depth: 1,
    );
    expect(result.anatomical, isTrue);
    expect(result.voxels, hasLength(1));
  });
}
