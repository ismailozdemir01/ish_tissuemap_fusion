import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';

class FhirIntegrationService {
  final Uri baseUrl;
  final String? accessToken;
  final String observationCodeSystem;
  final String observationCode;
  final String observationDisplay;

  FhirIntegrationService({
    required String baseUrl,
    this.accessToken,
    required this.observationCodeSystem,
    required this.observationCode,
    required this.observationDisplay,
  }) : baseUrl = Uri.parse(baseUrl);

  Map<String, String> get _headers => {
        'Accept': 'application/fhir+json',
        'Content-Type': 'application/fhir+json',
        if (accessToken != null && accessToken!.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

  Future<Map<String, dynamic>> fetchPatientRecord(String patientId) async {
    final response = await http.get(
      baseUrl.resolve('Patient/${Uri.encodeComponent(patientId)}'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw StateError('FHIR Patient request failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendScanToFhir(
    ChronosSnapshot snapshot,
    String patientId,
  ) async {
    final observation = <String, dynamic>{
      'resourceType': 'Observation',
      'status': 'final',
      'code': {
        'coding': [
          {
            'system': observationCodeSystem,
            'code': observationCode,
            'display': observationDisplay,
          }
        ]
      },
      'subject': {'reference': 'Patient/$patientId'},
      'effectiveDateTime': snapshot.timestamp.toUtc().toIso8601String(),
      'valueQuantity': {
        'value': snapshot.averageFusionScore,
        'unit': 'score',
      },
    };

    final response = await http.post(
      baseUrl.resolve('Observation'),
      headers: _headers,
      body: jsonEncode(observation),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError('FHIR Observation request failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
