import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';

/// FHIR (Fast Healthcare Interoperability Resources) entegrasyonu.
/// Sağlık verilerini hastanelerle paylaşmak için standart API.
class FhirIntegrationService {
  final String _baseUrl = 'https://your-fhir-server.com/fhir';

  /// Kullanıcının hastane kayıtlarını getirir (FHIR Patient ve Observation).
  Future<Map<String, dynamic>> fetchPatientRecord(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/Patient/$patientId'),
        headers: {'Authorization': 'Bearer YOUR_ACCESS_TOKEN'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Kayıt bulunamadı'};
      }
    } catch (e) {
      return {'error': 'Bağlantı hatası: $e'};
    }
  }

  /// ISH tarama verisini FHIR Observation kaynağına dönüştürür ve gönderir.
  Future<bool> sendScanToFhir(ChronosSnapshot snapshot, String patientId) async {
    try {
      // Observation JSON'u oluştur
      final observation = {
        'resourceType': 'Observation',
        'status': 'final',
        'category': [
          {'coding': [{'system': 'http://terminology.hl7.org/CodeSystem/observation-category', 'code': 'exam'}]}
        ],
        'code': {
          'coding': [
            {
              'system': 'http://loinc.org',
              'code': '87162-2',
              'display': 'Doku yoğunluk indeksi'
            }
          ]
        },
        'subject': {'reference': 'Patient/$patientId'},
        'effectiveDateTime': snapshot.timestamp.toIso8601String(),
        'valueQuantity': {
          'value': snapshot.averageFusionScore,
          'unit': '0-1 skalası',
          'system': 'http://unitsofmeasure.org',
          'code': '{score}'
        },
        'note': [
          {'text': 'ISH TissueMap Fusion taraması sonucu'}
        ],
        'component': snapshot.pointData.take(10).map((p) {
          return {
            'code': {'coding': [{'system': 'http://loinc.org', 'code': '87162-2'}]},
            'valueQuantity': {
              'value': p['fusionScore'],
              'unit': '0-1 skalası'
            }
          };
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/Observation'),
        headers: {
          'Content-Type': 'application/fhir+json',
          'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
        },
        body: json.encode(observation),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('FHIR gönderme hatası: $e');
      return false;
    }
  }

  /// Doktorla veri paylaşımı için kısa link oluşturur (demo).
  String createShareLink(String scanId) {
    return 'https://ish.app/share/$scanId';
  }
}
