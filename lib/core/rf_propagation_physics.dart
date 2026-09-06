import 'dart:math' as math;

class RfPropagationPhysics {
  static const double speedOfLightMetersPerSecond = 299792458.0;

  const RfPropagationPhysics._();

  static double wavelengthMeters(double frequencyMHz) {
    if (!frequencyMHz.isFinite || frequencyMHz <= 0) {
      throw ArgumentError('Invalid RF frequency');
    }
    return speedOfLightMetersPerSecond / (frequencyMHz * 1000000.0);
  }

  static double freeSpacePathLossDb({
    required double frequencyMHz,
    required double distanceMeters,
  }) {
    if (!distanceMeters.isFinite || distanceMeters <= 0) {
      throw ArgumentError('Invalid RF distance');
    }
    final wavelength = wavelengthMeters(frequencyMHz);
    return 20.0 * math.log(4.0 * math.pi * distanceMeters / wavelength) / math.ln10;
  }

  static double pathLengthMeters({
    required List<double> source,
    required List<double> target,
    double scale = 1.0,
  }) {
    if (source.length != 3 || target.length != 3 ||
        source.any((v) => !v.isFinite) || target.any((v) => !v.isFinite) ||
        !scale.isFinite || scale <= 0) {
      throw ArgumentError('Invalid RF geometry');
    }
    final dx = target[0] - source[0];
    final dy = target[1] - source[1];
    final dz = target[2] - source[2];
    return math.sqrt(dx * dx + dy * dy + dz * dz) * scale;
  }
}
