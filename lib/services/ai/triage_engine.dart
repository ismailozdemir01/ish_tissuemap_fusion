import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';

/// Triage inference boundary. Clinical classifications are never fabricated.
/// A validated model and a validated feature schema must be present before
/// this service returns a clinical risk class.
class TriageEngine {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      _isLoaded = true;
    } catch (_) {
      _interpreter = null;
      _isLoaded = false;
    }
  }

  Future<Map<String, dynamic>> evaluate(ChronosSnapshot snapshot) async {
    if (!_isLoaded || _interpreter == null) {
      return _unavailable('MODEL_UNAVAILABLE: validated triage model is not configured.');
    }

    // The current repository has no validated feature contract for the model.
    // Do not manufacture a 4096-value tensor from synthetic sequences.
    return _unavailable(
      'INSUFFICIENT_DATA: validated model feature extraction is not configured.',
    );
  }

  Map<String, dynamic> _unavailable(String reason) => {
        'risk': 'UNKNOWN',
        'action': 'Klinik karar üretilemedi; doğrulanmış veri/model gereklidir.',
        'confidence': 0.0,
        'status': reason.split(':').first,
        'reason': reason,
      };
}
