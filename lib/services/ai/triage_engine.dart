import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:ish_tissuemap_fusion/services/storage/local_database.dart';
import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';

/// Yapay Zeka ile tarama sonuçlarını değerlendirir ve eylem önerisi sunar.
class TriageEngine {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  /// Model dosyasını assets/model.tflite'den yükler.
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('model.tflite');
      _isLoaded = true;
    } catch (e) {
      print('Model yüklenemedi: $e');
      _isLoaded = false;
    }
  }

  /// Son tarama verilerini modele sokar ve sonuç alır.
  /// [snapshot] kaydedilmiş ChronosSnapshot
  /// Geri dönüş: {"risk": "Düşük/Orta/Yüksek", "action": "Doktora görün/3 ay sonra gel/...", "confidence": 0.85}
  Future<Map<String, dynamic>> evaluate(ChronosSnapshot snapshot) async {
    if (!_isLoaded) {
      // Model yoksa basit kural tabanlı triyaj
      return _ruleBasedTriage(snapshot);
    }

    // Model için giriş tensörü hazırlama
    // TFLite girişi: [1, 64, 64, 1] veya özet istatistikler
    // Örnek: 64x64 ısı haritasını düzleştirip 4096 özellik olarak ver.
    List<double> input = _prepareInput(snapshot);
    var inputTensor = [input];
    var output = List.filled(1 * 3, 0.0).reshape([1, 3]); // 3 sınıf

    _interpreter?.run(inputTensor, output);
    
    // Çıktıyı analiz et
    List<double> probs = output[0].cast<double>();
    int maxIndex = probs.indexOf(probs.reduce(max));
    String risk = ['Düşük', 'Orta', 'Yüksek'][maxIndex];
    String action = _getActionForRisk(risk);
    
    return {
      'risk': risk,
      'action': action,
      'confidence': probs[maxIndex],
    };
  }

  /// Kural tabanlı triyaj (model yoksa veya yedek)
  Map<String, dynamic> _ruleBasedTriage(ChronosSnapshot snapshot) {
    double score = snapshot.averageFusionScore;
    String risk;
    String action;
    if (score < 0.3) {
      risk = 'Düşük';
      action = 'Normal, yıllık kontrol yeterli.';
    } else if (score < 0.6) {
      risk = 'Orta';
      action = 'Diyet ve egzersiz önerilir, 3 ay sonra tekrar tarayın.';
    } else {
      risk = 'Yüksek';
      action = 'En kısa sürede doktora başvurun.';
    }
    return {'risk': risk, 'action': action, 'confidence': 0.7};
  }

  String _getActionForRisk(String risk) {
    switch (risk) {
      case 'Düşük': return 'Normal, yıllık kontrol yeterli.';
      case 'Orta': return 'Diyet ve egzersiz önerilir, 3 ay sonra tekrar tarayın.';
      case 'Yüksek': return 'En kısa sürede doktora başvurun.';
      default: return 'Belirsiz';
    }
  }

  /// 64x64 ısı haritasını düzleştir ve normalize et
  List<double> _prepareInput(ChronosSnapshot snapshot) {
    // Burada snapshot.pointData'dan ısı haritası yeniden oluşturulup düzleştirilir.
    // Kısaca örnek: 64*64 = 4096 boyutlu liste
    List<double> flat = List.filled(4096, 0.0);
    // Gerçek kodda harita oluşturulup doldurulur
    // Bu örnek için rastgele değerler
    for (int i = 0; i < flat.length; i++) {
      flat[i] = (i % 100) / 100.0;
    }
    return flat;
  }
}
