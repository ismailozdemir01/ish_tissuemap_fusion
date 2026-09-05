import 'dart:math';
import 'package:vector_math/vector_math.dart' as vec;

/// Spektral analiz ile dokunun frekans imzasını çıkarır.
/// Yağ, kas, tümör gibi farklı dokular farklı frekans bantlarında emilim gösterir.
class SpectralAnalyzer {
  // Önceden belirlenmiş frekans bantları (Hz cinsinden)
  static const List<double> bandRanges = [500, 1000, 2000, 4000, 8000];

  /// Ham FFT verisini alır ve her bandın enerjisini hesaplar.
  /// Geriye 0-1 arası normalize edilmiş 5 bant enerjisi döner.
  List<double> analyzeSpectrum(List<Complex> fftData, int sampleRate) {
    if (fftData.isEmpty) return List.filled(bandRanges.length, 0.0);
    
    List<double> bandEnergies = [];
    int n = fftData.length;
    
    for (int i = 0; i < bandRanges.length; i++) {
      double lowFreq = bandRanges[i];
      double highFreq = (i < bandRanges.length - 1) ? bandRanges[i + 1] : sampleRate / 2;
      
      int lowIndex = (lowFreq * n / sampleRate).floor();
      int highIndex = (highFreq * n / sampleRate).ceil();
      if (lowIndex >= n) lowIndex = n - 1;
      if (highIndex >= n) highIndex = n - 1;
      
      double energy = 0.0;
      for (int j = lowIndex; j <= highIndex; j++) {
        double mag = sqrt(fftData[j].real * fftData[j].real + fftData[j].imag * fftData[j].imag);
        energy += mag * mag;
      }
      bandEnergies.add(energy);
    }
    
    // Normalize (max 1)
    double maxEnergy = bandEnergies.reduce(max);
    if (maxEnergy > 0) {
      bandEnergies = bandEnergies.map((e) => e / maxEnergy).toList();
    }
    return bandEnergies;
  }

  /// Enerji vektörünü doku tipi tahminine çevirir (basit sınıflandırma)
  String predictTissueType(List<double> energies) {
    // Bu örnekte basit eşik değerlerle tahmin yapıyoruz.
    // Gerçekte buraya bir ML modeli veya karar ağacı konabilir.
    double lowFreqEnergy = energies[0] + energies[1];
    double highFreqEnergy = energies[3] + energies[4];
    
    if (lowFreqEnergy > 1.2 && highFreqEnergy < 0.8) return "Yağ dokusu";
    if (lowFreqEnergy < 0.7 && highFreqEnergy > 1.0) return "Kas dokusu";
    if (lowFreqEnergy > 1.5 && highFreqEnergy > 0.9) return "Potansiyel tümör/iltihap";
    return "Normal doku";
  }
}

// Complex sınıfı (daha önce acoustic_service'de tanımlanmıştı, burada tekrar ediyoruz)
class Complex {
  final double real;
  final double imag;
  Complex(this.real, this.imag);
  Complex operator +(Complex other) => Complex(real + other.real, imag + other.imag);
  Complex operator -(Complex other) => Complex(real - other.real, imag - other.imag);
  Complex operator *(Complex other) => Complex(
    real * other.real - imag * other.imag,
    real * other.imag + imag * other.real
  );
  Complex operator *(double scalar) => Complex(real * scalar, imag * scalar);
}
