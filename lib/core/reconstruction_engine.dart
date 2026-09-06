import '../models/imaging_pipeline.dart';
import 'fusion_engine.dart';

abstract interface class ReconstructionAlgorithm {
  SignalModality get modality;
  bool get calibrated;
  ReconstructionResult reconstruct(List<FusionPoint> data);
}

class ReconstructionEngine {
  final Map<SignalModality, ReconstructionAlgorithm> _algorithms;

  ReconstructionEngine([Iterable<ReconstructionAlgorithm> algorithms = const []])
      : _algorithms = {for (final algorithm in algorithms) algorithm.modality: algorithm};

  void register(ReconstructionAlgorithm algorithm) => _algorithms[algorithm.modality] = algorithm;

  ReconstructionResult reconstruct(SignalModality modality, List<FusionPoint> data) {
    final algorithm = _algorithms[modality];
    if (algorithm == null) {
      return ReconstructionResult.unavailable(modality, 'RECONSTRUCTION_ALGORITHM_UNAVAILABLE');
    }
    if (!algorithm.calibrated) {
      return ReconstructionResult.unavailable(modality, 'RECONSTRUCTION_NOT_CALIBRATED');
    }
    if (data.isEmpty) {
      return ReconstructionResult.unavailable(modality, 'INSUFFICIENT_ACQUISITION_DATA');
    }
    return algorithm.reconstruct(data);
  }
}
