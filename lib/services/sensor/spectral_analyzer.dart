import 'dart:math';

/// Performs mathematical spectral feature extraction only. Tissue labels are
/// never inferred without a validated model.
class SpectralAnalyzer {
  static const List<double> bandRanges = [500, 1000, 2000, 4000, 8000];

  List<double> analyzeSpectrum(List<Complex> fftData, int sampleRate) {
    if (fftData.isEmpty || sampleRate <= 0) return List.filled(bandRanges.length, 0.0);
    var bandEnergies = <double>[];
    final n = fftData.length;
    for (var i = 0; i < bandRanges.length; i++) {
      final lowFreq = bandRanges[i];
      final highFreq = i < bandRanges.length - 1 ? bandRanges[i + 1] : sampleRate / 2;
      var lowIndex = (lowFreq * n / sampleRate).floor().clamp(0, n - 1);
      var highIndex = (highFreq * n / sampleRate).ceil().clamp(0, n - 1);
      if (highIndex < lowIndex) highIndex = lowIndex;
      var energy = 0.0;
      for (var j = lowIndex; j <= highIndex; j++) {
        final value = fftData[j];
        final mag = sqrt(value.real * value.real + value.imag * value.imag);
        energy += mag * mag;
      }
      bandEnergies.add(energy);
    }
    final maxEnergy = bandEnergies.reduce(max);
    if (maxEnergy > 0) bandEnergies = bandEnergies.map((e) => e / maxEnergy).toList();
    return bandEnergies;
  }

  /// Returns UNKNOWN until an externally validated tissue classifier is supplied.
  String predictTissueType(List<double> energies) {
    if (energies.length != bandRanges.length || energies.any((e) => !e.isFinite)) return 'UNKNOWN_INSUFFICIENT_SPECTRAL_DATA';
    return 'UNKNOWN_VALIDATED_TISSUE_MODEL_REQUIRED';
  }
}

class Complex {
  final double real;
  final double imag;
  const Complex(this.real, this.imag);
  Complex operator +(Complex other) => Complex(real + other.real, imag + other.imag);
  Complex operator -(Complex other) => Complex(real - other.real, imag - other.imag);
  Complex operator *(Complex other) => Complex(real * other.real - imag * other.imag, real * other.imag + imag * other.real);
}
