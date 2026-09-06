import '../models/imaging_pipeline.dart';
import 'fusion_engine.dart';
import 'reconstruction_engine.dart';
import 'signal_feature.dart';
import 'signal_pipeline.dart';
import 'sensor_synchronizer.dart';

class ImagingSessionResult {
  final PipelineState state;
  final List<RawSignalSample> raw;
  final List<RawSignalSample> processed;
  final List<FusionPoint> fused;
  final List<MultimodalFeatureSet> featureSets;
  final Map<SignalModality, ReconstructionResult> reconstructions;
  final String? reason;

  const ImagingSessionResult({
    required this.state, required this.raw, required this.processed,
    required this.fused, required this.featureSets, required this.reconstructions,
    this.reason,
  });
}

class ImagingOrchestrator {
  final SignalProcessingPipeline processing;
  final SensorSynchronizer synchronizer;
  final FusionEngine fusion;
  final ReconstructionEngine reconstruction;

  ImagingOrchestrator({
    this.processing = const SignalProcessingPipeline(),
    this.synchronizer = const SensorSynchronizer(),
    this.fusion = const FusionEngine(),
    ReconstructionEngine? reconstruction,
  }) : reconstruction = reconstruction ?? ReconstructionEngine();

  ImagingSessionResult process(List<RawSignalSample> raw) {
    if (raw.isEmpty) {
      return const ImagingSessionResult(state: PipelineState.unavailable, raw: [], processed: [], fused: [], featureSets: [], reconstructions: {}, reason: 'NO_ACQUISITION_DATA');
    }
    final processed = processing.denoise(raw);
    if (processed.isEmpty) {
      return ImagingSessionResult(state: PipelineState.unavailable, raw: raw, processed: processed, fused: const [], featureSets: const [], reconstructions: const {}, reason: 'NO_USABLE_SIGNAL');
    }
    final groups = synchronizer.align(processed);
    final featureSets = fusion.fuseFeatures(groups);
    final fused = fusion.fuse(groups);
    final modalities = featureSets.expand((s) => s.modalities).toSet();
    final reconstructions = <SignalModality, ReconstructionResult>{};
    for (final modality in modalities) {
      reconstructions[modality] = reconstruction.reconstructFeatures(modality, featureSets);
    }
    final hasValidatedImage = reconstructions.values.any((r) => r.validated && r.volume.isNotEmpty);
    return ImagingSessionResult(
      state: hasValidatedImage ? PipelineState.complete : PipelineState.unavailable,
      raw: List.unmodifiable(raw), processed: List.unmodifiable(processed), fused: fused,
      featureSets: featureSets, reconstructions: Map.unmodifiable(reconstructions),
      reason: hasValidatedImage ? null : 'NO_VALIDATED_RECONSTRUCTION_ALGORITHM',
    );
  }
}
