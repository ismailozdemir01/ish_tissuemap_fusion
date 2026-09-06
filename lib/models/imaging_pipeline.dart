enum AcquisitionMode { phoneOnly, externalHardware, hybrid, pcOffload }

enum SignalModality { optical, magnetic, inertial, acoustic, radioFrequency, xray, ct, mri, ultrasound, external }

enum ProcessingLocation { phone, pc, hybrid }

enum PipelineState { idle, acquiring, processing, reconstructing, analyzing, complete, unavailable, error }

class RawSignalSample {
  final String sensorId;
  final SignalModality modality;
  final int timestampMicros;
  final List<double> values;
  final String unit;
  final double quality;
  final double? frequencyMHz;
  final int? channel;

  const RawSignalSample({
    required this.sensorId,
    required this.modality,
    required this.timestampMicros,
    required this.values,
    required this.unit,
    required this.quality,
    this.frequencyMHz,
    this.channel,
  });
}

class ReconstructedVoxel {
  final int x;
  final int y;
  final int z;
  final double value;
  final double uncertainty;

  const ReconstructedVoxel({required this.x, required this.y, required this.z, required this.value, required this.uncertainty});
}

class ReconstructionResult {
  final SignalModality modality;
  final int width;
  final int height;
  final int depth;
  final List<double> volume;
  final List<double> uncertainty;
  final String unit;
  final bool validated;
  final String? reason;

  const ReconstructionResult({
    required this.modality,
    required this.width,
    required this.height,
    required this.depth,
    required this.volume,
    required this.uncertainty,
    required this.unit,
    required this.validated,
    this.reason,
  });

  static ReconstructionResult unavailable(SignalModality modality, String reason) => ReconstructionResult(
        modality: modality,
        width: 0,
        height: 0,
        depth: 0,
        volume: const [],
        uncertainty: const [],
        unit: '',
        validated: false,
        reason: reason,
      );
}
