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

  Future<double> measureDensity() async {
    if (!_isInitialized) await init();

    final tone = _generateSineWave(18000, 0.05);
    final Uint8List audioData = Float32List.fromList(tone).buffer.asUint8List();

    await _player.startPlayerFromStream(
      codec: Codec.pcmFloat32,
      sampleRate: 44100,
      numChannels: 1,
    );
    await _player.feed(audioData);

    await _recorder.startRecorder(
      codec: Codec.pcmFloat32,
      sampleRate: 44100,
      numChannels: 1,
    );

    final recorded = await _recorder.getChunk();
    await _recorder.stopRecorder();

    final fftResult = _performFFT(recorded);
    final peakIndex = _findPeakFrequencyIndex(fftResult);
    if (peakIndex == 0) return 0.5;

    final timeDelay = peakIndex / 44100.0;
    return (1 - (timeDelay / 0.01)).clamp(0.0, 1.0);
  }

  List<double> _generateSineWave(int freq, double durationSec) {
    const sampleRate = 44100;
    final samples = (sampleRate * durationSec).floor();
    return List<double>.generate(
      samples,
      (i) => sin(2 * pi * freq * (i / sampleRate)),
    );
  }

  List<vec.Vector2> _performFFT(Uint8List rawData) {
    final n = rawData.length;
    if (n == 0) return const <vec.Vector2>[];
    final power = pow(2, (log(n) / ln2).ceil()).toInt();
    final data = List<vec.Vector2>.generate(
      power,
      (i) => i < n
          ? vec.Vector2(rawData[i] / 127.5 - 1.0, 0)
          : vec.Vector2.zero(),
    );

    final bits = (log(power) / ln2).floor();
    for (var i = 0; i < power; i++) {
      final rev = _reverseBits(i, bits);
      if (i < rev) {
        final temp = data[i];
        data[i] = data[rev];
        data[rev] = temp;
      }
    }

    for (var len = 2; len <= power; len <<= 1) {
      final angle = -2 * pi / len;
      final wLen = vec.Vector2(cos(angle), sin(angle));
      for (var i = 0; i < power; i += len) {
        var w = vec.Vector2(1, 0);
        for (var j = 0; j < len ~/ 2; j++) {
          final u = data[i + j];
          final v0 = data[i + j + len ~/ 2];
          final v = vec.Vector2(
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
    var result = 0;
    for (var i = 0; i < bits; i++) {
      result = (result << 1) | (x & 1);
      x >>= 1;
    }
    return result;
  }

  int _findPeakFrequencyIndex(List<vec.Vector2> fftData) {
    var maxMag = 0.0;
    var idx = 0;
    for (var i = 0; i < fftData.length ~/ 2; i++) {
      final value = fftData[i];
      final mag = sqrt(value.x * value.x + value.y * value.y);
      if (mag > maxMag) {
        maxMag = mag;
        idx = i;
      }
    }
    return idx;
  }

  Future<void> dispose() async {
    if (_player.isPlaying) await _player.stopPlayer();
    if (_isInitialized) {
      await _player.closePlayer();
      await _recorder.closeRecorder();
    }
    _isInitialized = false;
  }
}
