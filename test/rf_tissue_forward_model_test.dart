import 'package:flutter_test/flutter_test.dart';

import 'package:ish_tissuemap_fusion/core/rf_tissue_forward_model.dart';

class _Calibration implements RfTissueCalibration {
  @override
  String get calibrationId => 'test-calibration';

  @override
  bool get validated => true;

  @override
  double sensitivity(double frequencyMHz) => frequencyMHz / 1000.0;

  @override
  double attenuationNpPerMeter(double frequencyMHz) => 0.1;

  @override
  double? referenceRssiDbm(double frequencyMHz) => -50.0;
}

void main() {
  test('builds finite geometry-dependent forward matrix', () {
    final model = PhoneRfTissueForwardModel(
      modelId: 'test-rf-model',
      calibration: _Calibration(),
      voxelCount: 2,
    );

    final matrix = model.buildForwardMatrix(
      frequenciesMHz: [2400, 5200],
      voxelCoordinates: const [[0, 0, 0], [1, 0, 0]],
      measurementCoordinates: const [[0, 0, 1], [1, 0, 1]],
    );

    expect(matrix.length, 2);
    expect(matrix.every((row) => row.length == 2), isTrue);
    expect(matrix.expand((row) => row).every((v) => v.isFinite), isTrue);
  });

  test('requires measured reference for calibrated residuals', () {
    final model = PhoneRfTissueForwardModel(
      modelId: 'test-rf-model',
      calibration: _Calibration(),
      voxelCount: 1,
    );
    expect(model.referenceRssiDbm(2400), -50.0);
  });
}
