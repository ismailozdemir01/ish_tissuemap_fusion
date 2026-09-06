enum MeasurementStatus {
  valid,
  unknown,
  unavailable,
  notConfigured,
  notCalibrated,
  insufficientData,
  modelUnavailable,
  invalid,
}

extension MeasurementStatusX on MeasurementStatus {
  bool get isUsable => this == MeasurementStatus.valid;

  String get wireValue => switch (this) {
        MeasurementStatus.valid => 'VALID',
        MeasurementStatus.unknown => 'UNKNOWN',
        MeasurementStatus.unavailable => 'UNAVAILABLE',
        MeasurementStatus.notConfigured => 'NOT_CONFIGURED',
        MeasurementStatus.notCalibrated => 'NOT_CALIBRATED',
        MeasurementStatus.insufficientData => 'INSUFFICIENT_DATA',
        MeasurementStatus.modelUnavailable => 'MODEL_UNAVAILABLE',
        MeasurementStatus.invalid => 'INVALID',
      };
}
