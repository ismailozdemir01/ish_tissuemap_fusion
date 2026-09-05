import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Sesli komut (TTS) ve titreşim (Haptic) ile kullanıcıyı yönlendirir.
class GuidanceService {
  final FlutterTts _tts = FlutterTts();
  final HapticFeedback _haptic = HapticFeedback;

  Future<void> initTTS() async {
    await _tts.setLanguage('tr-TR');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
  }

  /// Sesli uyarı ver
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  /// Hızlı titreşim (hata veya uyarı)
  void vibrateWarning() {
    HapticFeedback.vibrate();
    Future.delayed(Duration(milliseconds: 200), () {
      HapticFeedback.vibrate();
    });
  }

  /// Yavaş titreşim (doğru yönde ilerleme)
  void vibrateSuccess() {
    HapticFeedback.lightImpact();
  }

  /// Tarama hızı çok yüksekse uyar
  void checkSpeed(double speed, Function onSlowDown) {
    if (speed > 0.05) { // saniyede 5 cm'den hızlı
      vibrateWarning();
      speak('Lütfen daha yavaş hareket ettirin.');
    } else {
      vibrateSuccess();
    }
  }

  /// Belirli bir bölgeye gelindiğinde bilgi ver
  void announceRegion(String region) {
    speak('Şu anda $region bölgesini tarıyorsunuz.');
  }

  void dispose() {
    _tts.stop();
  }
}
