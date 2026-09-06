enum EmergencyState { stable, warning, critical, unknown }

class EmergencyDecision {
  final EmergencyState state;
  final double confidence;
  final List<String> evidence;
  final DateTime timestamp;

  const EmergencyDecision({
    required this.state,
    required this.confidence,
    required this.evidence,
    required this.timestamp,
  });

  static EmergencyDecision unknown(String reason) => EmergencyDecision(
        state: EmergencyState.unknown,
        confidence: 0,
        evidence: [reason],
        timestamp: DateTime.now().toUtc(),
      );
}
