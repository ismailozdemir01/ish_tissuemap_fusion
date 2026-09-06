import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:vector_math/vector_math.dart' as vec;

class AcousticService {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isInitialized = false;

  Future<void> init() async {
    if (!_isInitialized) {
      await _player.openPlayer();
      await _recorder.openRecorder();
      _isInitialized = true;
    }
  }

  Future<double> measureDensity() async {
    if (!_isInitialized) await init();

    // 18kHz'lik sinüs dalgası üret (50ms)
    final tone = _generateSineWave(18000, 0.05);
    final Uint8List audioData = Float32List.fromList(tone).buffer.asUint8List();

    // Sesi gönder
    await _player.startPlayerFromStream(
      codec: Codec.pcmFloat32,
      sampleRate: 44100,
      numChannels: 1,
    );
    await _player.feed(audioData);

    // Kaydet
    await _recorder.startRecorder(
      codec: Codec.pcmFloat32,
      sampleRate: 44100,
      numChannels: 1,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    final recorded = await _recorder.getChunk();
    await _recorder.stopRecorder();

    // FFT ile gecikme analizi
    final fftResult = _performFFT(recorded);
    final peakIndex = _findPeakFrequencyIndex(fftResult);
    if (peakIndex == 0) return 0.5;
    final timeDelay = peakIndex / 44100.0;
    return (1 - (timeDelay / 0.01)).clamp(0.0, 1.0);
  }

  List<double> _generateSineWave(int freq, double durationSec) {
    final samples = (44100 * durationSec).floor();
    List<double> wave = [];
    for (int i = 0; i < samples; i++) {
      double time = i / 44100.0;
      wave.add(sin(2 * pi * freq * time));
    }
    return wave;
  }

  List<Complex> _performFFT(Uint8List rawData) {
    int n = rawData.length;
    int power = pow(2, (log(n) / ln2).ceil()).toInt();
    List<Complex> data = List.generate(power, (i) {
      if (i < n) return Complex(rawData[i] / 127.5 - 1.0, 0);
      return Complex(0, 0);
    });

    int bits = (log(power) / ln2).floor();
    for (int i = 0; i < power; i++) {
      int rev = _reverseBits(i, bits);
      if (i < rev) {
        Complex temp = data[i];
        data[i] = data[rev];
        data[rev] = temp;
      }
    }
    for (int len = 2; len <= power; len <<= 1) {
      double angle = -2 * pi / len;
      Complex wLen = Complex(cos(angle), sin(angle));
      for (int i = 0; i < power; i += len) {
        Complex w = Complex(1, 0);
        for (int j = 0; j < len ~/ 2; j++) {
          Complex u = data[i + j];
          Complex v = data[i + j + len ~/ 2] * w;
          data[i + j] = u + v;
          data[i + j + len ~/ 2] = u - v;
          w *= wLen;
        }
      }
    }
    return data;
  }

  int _reverseBits(int x, int bits) {
    int res = 0;
    for (int i = 0; i < bits; i++) {
      res = (res << 1) | (x & 1);
      x >>= 1;
    }
    return res;
  }

  int _findPeakFrequencyIndex(List<Complex> fftData) {
    double maxMag = 0.0;
    int idx = 0;
    for (int i = 0; i < fftData.length ~/ 2; i++) {
      double mag = sqrt(fftData[i].real * fftData[i].real + fftData[i].imag * fftData[i].imag);
      if (mag > maxMag) { maxMag = mag; idx = i; }
    }
    return idx;
  }
}

class Complex {
  final double real, imag;
  Complex(this.real, this.imag);
  Complex operator +(Complex other) => Complex(real + other.real, imag + other.imag);
  Complex operator -(Complex other) => Complex(real - other.real, imag - other.imag);
  Complex operator *(Complex other) => Complex(
    real * other.real - imag * other.imag,
    real * other.imag + imag * other.real
  );
  Complex operator *(double scalar) => Complex(real * scalar, imag * scalar);
}
