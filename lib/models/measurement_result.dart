import 'measurement_status.dart';

enum MeasurementSource { phone, medicalDevice, hybrid }

class MeasurementResult {
  final String metric;
  final double? value;
  final String unit;
  final MeasurementStatus status;
  final MeasurementSource source;
  final double confidence;
  final DateTime timestamp;
  final String? deviceId;
  final String? reason;

  const MeasurementResult({
    required this.metric,
    required this.value,
    required this.unit,
    required this.status,
    required this.source,
    required this.confidence,
    required this.timestamp,
    this.deviceId,
    this.reason,
  });

  factory MeasurementResult.unavailable({
    required String metric,
    required String unit,
    required MeasurementSource source,
    String? reason,
  }) => MeasurementResult(
        metric: metric,
        value: null,
        unit: unit,
        status: MeasurementStatus.unavailable,
        source: source,
        confidence: 0,
        timestamp: DateTime.now().toUtc(),
        reason: reason,
      );

  Map<String, Object?> toJson() => {
        'metric': metric,
        'value': value,
        'unit': unit,
        'status': status.wireValue,
        'source': source.name,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'deviceId': deviceId,
        'reason': reason,
      };
}
