import '../models/imaging_pipeline.dart';
import 'fusion_engine.dart';
import 'signal_feature.dart';

abstract interface class ReconstructionAlgorithm {
  SignalModality get modality;
  bool get calibrated;
  ReconstructionResult reconstruct(List<FusionPoint> data);
}

abstract interface class FeatureReconstructionAlgorithm {
  SignalModality get modality;
  bool get calibrated;
  ReconstructionResult reconstructFeatures(List<MultimodalFeatureSet> data);
}

class ReconstructionEngine {
  final Map<SignalModality, ReconstructionAlgorithm> _algorithms;
  final Map<SignalModality, FeatureReconstructionAlgorithm> _featureAlgorithms;

  ReconstructionEngine({
    Iterable<ReconstructionAlgorithm> algorithms = const [],
    Iterable<FeatureReconstructionAlgorithm> featureAlgorithms = const [],
  })  : _algorithms = {for (final algorithm in algorithms) algorithm.modality: algorithm},
        _featureAlgorithms = {for (final algorithm in featureAlgorithms) algorithm.modality: algorithm};

  void register(ReconstructionAlgorithm algorithm) => _algorithms[algorithm.modality] = algorithm;
  void registerFeatureAlgorithm(FeatureReconstructionAlgorithm algorithm) => _featureAlgorithms[algorithm.modality] = algorithm;

  ReconstructionResult reconstruct(SignalModality modality, List<FusionPoint> data) {
    final algorithm = _algorithms[modality];
    if (algorithm == null) return ReconstructionResult.unavailable(modality, 'RECONSTRUCTION_ALGORITHM_UNAVAILABLE');
    if (!algorithm.calibrated) return ReconstructionResult.unavailable(modality, 'RECONSTRUCTION_NOT_CALIBRATED');
    if (data.isEmpty) return ReconstructionResult.unavailable(modality, 'INSUFFICIENT_ACQUISITION_DATA');
    return algorithm.reconstruct(data);
  }

  ReconstructionResult reconstructFeatures(SignalModality modality, List<MultimodalFeatureSet> data) {
    final algorithm = _featureAlgorithms[modality];
    if (algorithm == null) return ReconstructionResult.unavailable(modality, 'FEATURE_RECONSTRUCTION_ALGORITHM_UNAVAILABLE');
    if (!algorithm.calibrated) return ReconstructionResult.unavailable(modality, 'RECONSTRUCTION_NOT_CALIBRATED');
    if (data.isEmpty) return ReconstructionResult.unavailable(modality, 'INSUFFICIENT_ACQUISITION_DATA');
    return algorithm.reconstructFeatures(data);
  }
}
