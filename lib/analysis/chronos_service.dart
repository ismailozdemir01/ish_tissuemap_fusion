import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';
import 'package:ish_tissuemap_fusion/services/storage/local_database.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class ChronosService {
  final LocalDatabase _db = LocalDatabase();

  // Yeni taramayı kaydet
  Future<void> saveCurrentScan(ChronosSnapshot snapshot) async {
    await _db.saveSnapshot(snapshot);
  }

  // Tüm geçmiş taramaları getir (tarihe göre sıralı)
  Future<List<ChronosSnapshot>> loadAllScans() async {
    return await _db.getAllSnapshots();
  }

  // Eski ve yeni taramayı karşılaştır, overlay için fark matrisi döndür
  List<List<double>> compareOverlay(ChronosSnapshot old, ChronosSnapshot current) {
    // Varsayılan 64x64 grid
    List<List<double>> diffGrid = List.generate(64, (_) => List.filled(64, 0.0));

    // Gerçek IDW interpolasyonu yerine basitçe nokta bazlı karşılaştırma
    // (Gerçekte burada iki harita çakıştırılır ve piksel piksel fark alınır)
    Map<String, double> oldMap = {};
    for (var json in old.pointData) {
      String key = "${json['x']},${json['y']}";
      oldMap[key] = json['fusionScore'] as double;
    }

    for (var json in current.pointData) {
      String key = "${json['x']},${json['y']}";
      double oldVal = oldMap[key] ?? 0.0;
      double newVal = json['fusionScore'] as double;
      int ix = ((json['x'] as double) * 64).floor().clamp(0, 63);
      int iy = ((json['y'] as double) * 64).floor().clamp(0, 63);
      diffGrid[ix][iy] = (newVal - oldVal).abs(); // Mutlak fark
    }
    return diffGrid;
  }

  // Trend analizi: Ortalamaları grafik için döndür
  List<Map<String, dynamic>> getTrendData(List<ChronosSnapshot> scans) {
    List<Map<String, dynamic>> data = [];
    for (var s in scans) {
      data.add({
        'date': DateFormat('dd MMM').format(s.timestamp),
        'score': s.averageFusionScore,
      });
    }
    return data;
  }
}
