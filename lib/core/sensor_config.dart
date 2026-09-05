library sensor_config;

/// Configuration values for physical sensor acquisition.
///
/// These values describe acquisition parameters and reference ranges only.
/// They do not constitute a medical diagnostic model or clinical threshold.
class SensorConfig {
  /// Nominal acoustic excitation frequency in Hz.
  ///
  /// 18 kHz is near the upper edge of human hearing, not reliably ultrasonic
  /// for every person or every device. Hardware capability must be verified.
  static const int acousticFrequency = 18000;

  /// Nominal audio sample rate in samples/second.
  static const int sampleRate = 44100;

  /// Excitation duration in milliseconds.
  static const int pingDurationMs = 50;

  /// Approximate geomagnetic field reference in microtesla.
  ///
  /// This is an environmental reference, not a tissue-conductivity baseline.
  static const double baselineEMF = 50.0;

  /// Example acquisition anomaly threshold in microtesla.
  ///
  /// Interpretation must be calibrated against the actual sensor and
  /// measurement environment before being used for any scientific claim.
  static const double anomalyThresholdEMF = 2.5;

  /// Relative fusion weights for the measurement visualization layer.
  static const double densityWeight = 1.2;
  static const double conductivityWeight = 0.8;
}
