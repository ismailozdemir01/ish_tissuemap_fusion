import 'package:flutter_test/flutter_test.dart';
import 'package:ish_tissuemap_fusion/models/measurement_result.dart';
import 'package:ish_tissuemap_fusion/models/measurement_status.dart';
import 'package:ish_tissuemap_fusion/services/emergency/emergency_engine.dart';
import 'package:ish_tissuemap_fusion/services/emergency/emergency_state.dart';

void main() {
  test('measurement status only treats VALID as usable', () {
    expect(MeasurementStatus.valid.isUsable, isTrue);
    expect(MeasurementStatus.unknown.isUsable, isFalse);
    expect(MeasurementStatus.modelUnavailable.isUsable, isFalse);
  });

  test('measurement serializes provenance and status', () {
    final result = MeasurementResult(
      metric: 'spo2',
      value: 98,
      unit: '%',
      status: MeasurementStatus.valid,
      source: MeasurementSource.medicalDevice,
      confidence: 0.99,
      timestamp: DateTime.utc(2026, 1, 1),
      deviceId: 'device-1',
    );
    final json = result.toJson();
    expect(json['status'], 'VALID');
    expect(json['source'], 'medicalDevice');
    expect(json['deviceId'], 'device-1');
  });

  test('emergency engine never fabricates a decision without configured rules', () {
    final engine = EmergencyEngine();
    final decision = engine.evaluate(const []);
    expect(decision.state, EmergencyState.unknown);
    expect(decision.confidence, 0);
  });
}
