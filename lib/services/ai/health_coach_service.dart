import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';
import 'package:ish_tissuemap_fusion/models/health_tip.dart';

/// Yapay zeka tabanlı sağlık koçu.
/// Verilere göre kişiselleştirilmiş öneriler sunar.
class HealthCoachService {
  List<HealthTip> _tips = [];

  HealthCoachService() {
    _loadDefaultTips();
  }

  void _loadDefaultTips() {
    _tips = [
      HealthTip(
        id: '1',
        category: 'Beslenme',
        title: 'Anti-İnflamatuar Beslenme',
        description: 'Zencefil, zerdeçal ve yeşil yapraklı sebzeler iltihabı azaltır.',
        priority: 1,
      ),
      HealthTip(
        id: '2',
        category: 'Egzersiz',
        title: 'Haftada 3 Kez Yürüyüş',
        description: 'Günde 30 dakika tempolu yürüyüş karaciğer yağlanmasını azaltır.',
        priority: 2,
      ),
      HealthTip(
        id: '3',
        category: 'Uyku',
        title: 'Düzenli Uyku Saati',
        description: 'Gece 23:00-07:00 arası uyumak hormonal dengeyi korur.',
        priority: 1,
      ),
      HealthTip(
        id: '4',
        category: 'Stres',
        title: 'Meditasyon ve Nefes',
        description: 'Günde 5 dakika derin nefes egzersizi kortizol seviyesini düşürür.',
        priority: 2,
      ),
      HealthTip(
        id: '5',
        category: 'Su Tüketimi',
        title: 'Günde 2 Litre Su',
        description: 'Vücut ağırlığınızın her kilosu için 30 ml su için.',
        priority: 3,
      ),
    ];
  }

  /// Son tarama verisine göre öneri listesi döndürür.
  List<HealthTip> getPersonalizedTips(ChronosSnapshot snapshot) {
    double score = snapshot.averageFusionScore;
    List<HealthTip> personalized = [];

    if (score > 0.6) {
      personalized.addAll(_tips.where((t) => t.category == 'Beslenme' || t.category == 'Egzersiz'));
    } else if (score > 0.3) {
      personalized.addAll(_tips.where((t) => t.category == 'Su Tüketimi' || t.category == 'Uyku'));
    } else {
      personalized.addAll(_tips.where((t) => t.category == 'Stres' || t.category == 'Uyku'));
    }

    // Önceliğe göre sırala
    personalized.sort((a, b) => a.priority.compareTo(b.priority));
    
    // En fazla 5 öneri göster
    return personalized.take(5).toList();
  }

  /// Haftalık sağlık özeti oluşturur.
  Map<String, dynamic> generateWeeklySummary(List<ChronosSnapshot> last7Scans) {
    if (last7Scans.isEmpty) {
      return {
        'message': 'Henüz yeterli veri yok.',
        'trend': 'Belirsiz',
        'averageScore': 0.0,
      };
    }

    double avgScore = last7Scans.fold(0.0, (sum, s) => sum + s.averageFusionScore) / last7Scans.length;
    double firstScore = last7Scans.first.averageFusionScore;
    double lastScore = last7Scans.last.averageFusionScore;
    String trend = (lastScore < firstScore) ? 'İyileşme' : (lastScore > firstScore ? 'Kötüleşme' : 'Sabit');

    return {
      'message': 'Son 7 günlük tarama özetiniz:',
      'trend': trend,
      'averageScore': avgScore,
      'startScore': firstScore,
      'endScore': lastScore,
      'recommendation': trend == 'Kötüleşme' ? 'Diyet ve egzersize ağırlık verin.' : 'Sağlıklı gidişat, devam edin!',
    };
  }
}
