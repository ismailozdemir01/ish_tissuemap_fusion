import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';

/// Acil durum yönetimi: SOS, triyaj, konum ve yönlendirme.
class EmergencyService {
  /// Tek dokunuşla SOS mesajı gönderir (SMS veya e-posta).
  Future<void> sendSOS(String phoneNumber, String patientName, double riskScore) async {
    Position position = await _getCurrentLocation();
    String message = '''
🚨 ACİL DURUM!
İsim: $patientName
Risk Skoru: ${(riskScore * 100).toInt()}%
Konum: https://maps.google.com/?q=${position.latitude},${position.longitude}
ISH TissueMap Fusion tarama sonucuna göre acil sağlık yardımı gerekiyor.
''';

    // SMS ile gönder (Android/iOS)
    final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      // E-posta yedek
      final emailUri = Uri.parse(
        'mailto:$phoneNumber?subject=ISH Acil Durum&body=${Uri.encodeComponent(message)}'
      );
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    }
  }

  /// Semptomlara göre aciliyet seviyesi belirler (triage).
  Map<String, dynamic> triage(ChronosSnapshot snapshot, List<String> symptoms) {
    double score = snapshot.averageFusionScore;
    String level;
    String action;

    // Skor bazlı
    if (score > 0.7) {
      level = 'KIRMIZI (Acil)';
      action = 'Ambulans çağırın veya en yakın acil servise gidin.';
    } else if (score > 0.5) {
      level = 'SARI (Orta)';
      action = 'En kısa sürede doktora başvurun, randevu alın.';
    } else {
      level = 'YEŞİL (Düşük)';
      action = 'Takip edin, 1 ay sonra tekrar tarayın.';
    }

    // Semptom kontrolü
    List<String> criticalSymptoms = ['göğüs ağrısı', 'nefes darlığı', 'bayılma', 'konuşma bozukluğu'];
    for (var s in symptoms) {
      if (criticalSymptoms.contains(s.toLowerCase())) {
        level = 'KIRMIZI (Acil)';
        action = 'AMBULANS ÇAĞIRIN! 112';
        break;
      }
    }

    return {
      'level': level,
      'action': action,
      'score': score,
      'symptoms': symptoms,
    };
  }

  /// En yakın sağlık kuruluşlarına yönlendirir.
  Future<void> redirectToNearestHospital() async {
    Position position = await _getCurrentLocation();
    String url = 'https://www.google.com/maps/search/hastane+acil+servis/@${position.latitude},${position.longitude},15z';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Mevcut konumu al (izinler kontrol edilmeli).
  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
