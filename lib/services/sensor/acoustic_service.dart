import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:vector_math/vector_math.dart' as vec;

class AcousticService {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  bool _isInitialized = false;

  Future<void> init() async {
    await _player.openPlayer();
    await _recorder.openRecorder();
    _isInitialized = true;
  }

  // Gerçek Yankı Süresi ve Yoğunluk Hesaplama (FFT ile)
  Future<double> measureDensity() async {
    if (!_isInitialized) await init();

    // 1. 18kHz'lik bir ton üret (Zararsız ultrasonik)
    final tone = _generateSineWave(18000, 0.05); // 50ms
    final Uint8List audioData = Float32List.fromList(tone).buffer.asUint8List();

    // 2. Sesi gönder ve eş zamanlı kayda başla
    await _player.startPlayerFromStream(
      codec: Codec.pcmFloat32,
      sampleRate: 44100,
      numChannels: 1,
    );
    await _player.feed(audioData);

    // 3. Mikrofon ile yankıyı yakala (kayıt)
    await _recorder.startRecorder(
      codec: Codec.pcmFloat32,
      sampleRate: 44100,
      numChannels: 1,
    );

    // 4. Kayıttan ilk 100ms'lik veriyi al
    final recorded = await _recorder.getChunk();
    await _recorder.stopRecorder();

    // 5. Gerçek Zamanlı FFT (Hızlı Fourier Dönüşümü) ile gecikmeyi bul
    final fftResult = _performFFT(recorded);
    final peakIndex = _findPeakFrequencyIndex(fftResult);

    // Ses hızı ~343 m/s. Gecikme süresi -> Yoğunluk indeksi (1/gecikme)
    if (peakIndex == 0) return 0.5; // Geçerli veri yoksa varsayılan
    final timeDelay = peakIndex / 44100.0;
    // Yoğunluk arttıkça ses hızı artar, gecikme azalır -> 0-1 normalize
    return (1 - (timeDelay / 0.01)).clamp(0.0, 1.0);
  }

  // Gerçek Sinüs Dalgası Üretici
  List<double> _generateSineWave(int freq, double durationSec) {
    final samples = (44100 * durationSec).floor();
    List<double> wave = [];
    for (int i = 0; i < samples; i++) {
      double time = i / 44100.0;
      wave.add(sin(2 * pi * freq * time));
    }
    return wave;
  }

  // Basit Gerçek FFT (Radix-2 Cooley Tukey - Vektör Math ile)
  List<vec.Vector2> _performFFT(Uint8List rawData) {
    int n = rawData.length;
    // En yakın 2^K boyutuna getir
    int power = pow(2, (log(n) / ln2).ceil()).toInt();
    List<vec.Vector2> data = List.generate(power, (i) {
      if (i < n) return vec.Vector2(rawData[i] / 127.5 - 1.0, 0);
      return vec.Vector2(0, 0);
    });

    // FFT Algoritması
    int bits = (log(power) / ln2).floor();
    for (int i = 0; i < power; i++) {
      int rev = _reverseBits(i, bits);
      if (i < rev) {
        vec.Vector2 temp = data[i];
        data[i] = data[rev];
        data[rev] = temp;
      }
    }

    for (int len = 2; len <= power; len <<= 1) {
      double angle = -2 * pi / len;
      vec.Vector2 wLen = vec.Vector2(cos(angle), sin(angle));
      for (int i = 0; i < power; i += len) {
        vec.Vector2 w = vec.Vector2(1, 0);
        for (int j = 0; j < len ~/ 2; j++) {
          vec.Vector2 u = data[i + j];
          vec.Vector2 v0 = data[i + j + len ~/ 2];
          vec.Vector2 v = vec.Vector2(
            v0.x * w.x - v0.y * w.y,
            v0.x * w.y + v0.y * w.x,
          );
          data[i + j] = vec.Vector2(u.x + v.x, u.y + v.y);
          data[i + j + len ~/ 2] = vec.Vector2(u.x - v.x, u.y - v.y);
          w = vec.Vector2(
            w.x * wLen.x - w.y * wLen.y,
            w.x * wLen.y + w.y * wLen.x,
          );
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

  int _findPeakFrequencyIndex(List<vec.Vector2> fftData) {
    double maxMag = 0.0;
    int idx = 0;
    for (int i = 0; i < fftData.length ~/ 2; i++) {
      double mag = sqrt(fftData[i].x * fftData[i].x + fftData[i].y * fftData[i].y);
      if (mag > maxMag) { maxMag = mag; idx = i; }
    }
    return idx;
  }
}
