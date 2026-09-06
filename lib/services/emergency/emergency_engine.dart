import '../../models/measurement_result.dart';
import 'emergency_state.dart';

class EmergencyEngine {
  EmergencyDecision evaluate(Iterable<MeasurementResult> measurements) {
    final usable = measurements.where((m) => m.status.isUsable && m.value != null).toList();
    if (usable.isEmpty) {
      return EmergencyDecision.unknown(
        'No validated measurements are available for emergency assessment.',
      );
    }

    // This engine deliberately does not invent clinical thresholds.
    // Device-specific validated rules/models must be supplied before a
    // measurement can cause a clinical emergency classification.
    return EmergencyDecision.unknown(
      'Validated clinical decision rules are not configured for the supplied measurements.',
    );
  }
}
