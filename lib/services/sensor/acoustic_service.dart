/// Acoustic sensing boundary.
///
/// A phone microphone/speaker pair can capture acoustic telemetry, but this
/// repository does not contain a validated transducer geometry, calibration
/// curve, time-of-flight protocol, or tissue model. Therefore this service
/// refuses to return a fabricated "density" value.
class AcousticService {
  bool _isInitialized = false;

  Future<void> init() async {
    _isInitialized = true;
  }

  Future<double> measureDensity() async {
    if (!_isInitialized) await init();
    throw StateError(
      'NOT_CALIBRATED: validated acoustic tissue-density measurement is not configured.',
    );
  }

  Future<void> dispose() async {
    _isInitialized = false;
  }
}
