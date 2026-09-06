import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Sesli komut (TTS) ve titreşim (Haptic) ile kullanıcıyı yönlendirir.
class GuidanceService {
  final FlutterTts _tts = FlutterTts();

  Future<void> initTTS() async {
    await _tts.setLanguage('tr-TR');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
  }

  Future<void> speak(String text) async => _tts.speak(text);

  void vibrateWarning() {
    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 200), HapticFeedback.vibrate);
  }

  void vibrateSuccess() => HapticFeedback.lightImpact();

  void checkSpeed(double speed, Function onSlowDown) {
    if (speed > 0.05) {
      vibrateWarning();
      speak('Lütfen daha yavaş hareket ettirin.');
    } else {
      vibrateSuccess();
    }
  }

  void announceRegion(String region) => speak('Şu anda $region bölgesini tarıyorsunuz.');

  void dispose() {
    _tts.stop();
  }
}
