import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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

  Future<void> startListening() async {
    if (_isListening) return;
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') _isListening = false;
      },
      onError: (_) => _isListening = false,
    );
    if (!available) return;
    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        _lastTranscription = result.recognizedWords;
        onResult?.call(_lastTranscription);
        _processCommand(_lastTranscription);
      },
      listenOptions: const stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
    );
  }

  void stopListening() {
    if (!_isListening) return;
    _speech.stop();
    _isListening = false;
  }

  Future<void> speak(String text) => _tts.speak(text);

  void _processCommand(String command) {
    final lower = command.toLowerCase();
    if (lower.contains('kaydet') || lower.contains('save')) {
      speak('Tarama sonuçları kaydediliyor.');
    } else if (lower.contains('rapor') || lower.contains('report')) {
      speak('PDF rapor oluşturuluyor.');
    } else if (lower.contains('yardım') || lower.contains('help')) {
      speak('Vücudunuzda telefonu gezdirin ve tarama ekranındaki yönlendirmeleri izleyin.');
    }
  }

  bool get isListening => _isListening;
  String get lastTranscription => _lastTranscription;

  void dispose() {
    _speech.stop();
    _tts.stop();
  }
}
