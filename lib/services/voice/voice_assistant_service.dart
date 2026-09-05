import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// Sesli asistan ile kullanıcı etkileşimi.
/// Konuşma tanıma ve metin okuma (TTS) özelliklerini içerir.
class VoiceAssistantService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isListening = false;
  String _lastTranscription = '';
  Function(String)? onResult;

  VoiceAssistantService() {
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('tr-TR');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
  }

  /// Sesli komut dinlemeye başlar
  Future<void> startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (error) => print('Ses hatası: $error'),
      );
      
      if (available) {
        _isListening = true;
        _speech.listen(
          onResult: (result) {
            _lastTranscription = result.recognizedWords;
            if (onResult != null) {
              onResult!(_lastTranscription);
            }
            _processCommand(_lastTranscription);
          },
          listenOptions: stt.ListenOptions(
            listenMode: stt.ListenMode.dictation,
            partialResults: true,
          ),
        );
      }
    }
  }

  /// Dinlemeyi durdurur
  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  /// Sesli yanıt verir
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  /// Komutları işler (örnek)
  void _processCommand(String command) {
    String lower = command.toLowerCase();
    if (lower.contains('kaydet') || lower.contains('save')) {
      speak('Tarama sonuçları kaydediliyor.');
      // Kaydetme fonksiyonu tetiklenir
    } else if (lower.contains('rapor') || lower.contains('report')) {
      speak('PDF rapor oluşturuluyor.');
      // PDF oluşturma tetiklenir
    } else if (lower.contains('yardım') || lower.contains('help')) {
      speak('Vücudunuzda telefonu gezdirin, kırmızı nokta takip edecek. Tarama başlatmak için ekrandaki butona basın.');
    } else {
      speak('Anlayamadım, lütfen tekrar eder misiniz?');
    }
  }

  bool get isListening => _isListening;
  String get lastTranscription => _lastTranscription;

  void dispose() {
    _speech.stop();
    _tts.stop();
  }
}
