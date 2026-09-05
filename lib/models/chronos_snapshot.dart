import 'package:hive/hive.dart';
import 'package:ish_tissuemap_fusion/models/tissue_point.dart';
import 'package:ish_tissuemap_fusion/models/anomaly_report.dart';
import 'package:intl/intl.dart';

@HiveType(typeId: 1)
class ChronosSnapshot {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime timestamp;
  @HiveField(2)
  final List<Map<String, dynamic>> pointData; // Serileştirilmiş TissuePoint
  @HiveField(3)
  final AnomalyReport? report;
  @HiveField(4)
  final double averageFusionScore; // Genel sağlık indeksi

  ChronosSnapshot({
    required this.id,
    required this.timestamp,
    required this.pointData,
    this.report,
    required this.averageFusionScore,
  });

  // Gerçek zamanlı karşılaştırma için metot
  double compareScore(ChronosSnapshot other) {
    return averageFusionScore - other.averageFusionScore; // Pozitif = kötüleşme
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': DateFormat('yyyy-MM-dd HH:mm').format(timestamp),
    'avgScore': averageFusionScore,
    'pointCount': pointData.length,
  };
}
