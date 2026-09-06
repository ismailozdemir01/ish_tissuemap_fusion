import '../models/imaging_pipeline.dart';
import 'fusion_engine.dart';
import 'reconstruction_engine.dart';
import 'sensor_synchronizer.dart';
import 'signal_pipeline.dart';

class ImagingSessionResult {
  final PipelineState state;
  final List<RawSignalSample> raw;
  final List<RawSignalSample> processed;
  final List<FusionPoint> fused;
  final Map<SignalModality, ReconstructionResult> reconstructions;
  final String? reason;

  const ImagingSessionResult({
    required this.state,
    required this.raw,
    required this.processed,
    required this.fused,
    required this.reconstructions,
    this.reason,
  });
}

class ImagingOrchestrator {
  final SignalProcessingPipeline processing;
  final SensorSynchronizer synchronizer;
  final FusionEngine fusion;
  final ReconstructionEngine reconstruction;

  const ImagingOrchestrator({
    this.processing = const SignalProcessingPipeline(),
    this.synchronizer = const SensorSynchronizer(),
    this.fusion = const FusionEngine(),
    this.reconstruction = const ReconstructionEngine(),
  });

  ImagingSessionResult process(List<RawSignalSample> raw) {
    if (raw.isEmpty) {
      return const ImagingSessionResult(state: PipelineState.unavailable, raw: [], processed: [], fused: [], reconstructions: {}, reason: 'NO_ACQUISITION_DATA');
    }
    final processed = processing.denoise(raw);
    final groups = synchronizer.align(processed);
    final fused = fusion.fuse(groups);
    final modalities = fused.expand((p) => p.modalities).toSet();
    final reconstructions = <SignalModality, ReconstructionResult>{};
    for (final modality in modalities) {
      reconstructions[modality] = reconstruction.reconstruct(modality, fused.where((p) => p.modalities.contains(modality)).toList());
    }
    return ImagingSessionResult(state: PipelineState.complete, raw: raw, processed: processed, fused: fused, reconstructions: reconstructions);
  }
}
