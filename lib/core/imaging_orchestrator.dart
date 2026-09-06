import '../models/imaging_pipeline.dart';
import 'fusion_engine.dart';
import 'image_analysis_engine.dart';
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
  final Map<SignalModality, ImageAnalysisResult> analyses;
  final String? reason;

  const ImagingSessionResult({
    required this.state,
    required this.raw,
    required this.processed,
    required this.fused,
    required this.featureSets,
    required this.reconstructions,
    required this.analyses,
    this.reason,
  });
}

class ImagingOrchestrator {
  final SignalProcessingPipeline processing;
  final SensorSynchronizer synchronizer;
  final FusionEngine fusion;
  final ReconstructionEngine reconstruction;
  final ImageAnalysisEngine analysis;

  ImagingOrchestrator({
    this.processing = const SignalProcessingPipeline(),
    this.synchronizer = const SensorSynchronizer(),
    this.fusion = const FusionEngine(),
    ReconstructionEngine? reconstruction,
    ImageAnalysisEngine? analysis,
  })  : reconstruction = reconstruction ?? ReconstructionEngine(),
        analysis = analysis ?? ImageAnalysisEngine();

  ImagingSessionResult process(List<RawSignalSample> raw) {
    if (raw.isEmpty) {
      return const ImagingSessionResult(
        state: PipelineState.unavailable,
        raw: [],
        processed: [],
        fused: [],
        featureSets: [],
        reconstructions: {},
        analyses: {},
        reason: 'NO_ACQUISITION_DATA',
      );
    }
    final processed = processing.denoise(raw);
    if (processed.isEmpty) {
      return ImagingSessionResult(
        state: PipelineState.unavailable,
        raw: List.unmodifiable(raw),
        processed: const [],
        fused: const [],
        featureSets: const [],
        reconstructions: const {},
        analyses: const {},
        reason: 'NO_USABLE_SIGNAL',
      );
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
      raw: List.unmodifiable(raw),
      processed: List.unmodifiable(processed),
      fused: fused,
      featureSets: featureSets,
      reconstructions: Map.unmodifiable(reconstructions),
      analyses: const {},
      reason: hasValidatedImage ? null : 'NO_VALIDATED_RECONSTRUCTION_ALGORITHM',
    );
  }

  Future<ImagingSessionResult> processAsync(List<RawSignalSample> raw) async {
    final base = process(raw);
    if (base.reconstructions.isEmpty) return base;
    final analyses = <SignalModality, ImageAnalysisResult>{};
    for (final entry in base.reconstructions.entries) {
      analyses[entry.key] = await analysis.analyze(entry.value);
    }
    final hasAnalyzedImage = analyses.values.any((a) => a.status == 'COMPLETE');
    return ImagingSessionResult(
      state: hasAnalyzedImage ? PipelineState.complete : base.state,
      raw: base.raw,
      processed: base.processed,
      fused: base.fused,
      featureSets: base.featureSets,
      reconstructions: base.reconstructions,
      analyses: Map.unmodifiable(analyses),
      reason: hasAnalyzedImage ? null : base.reason,
    );
  }
}
