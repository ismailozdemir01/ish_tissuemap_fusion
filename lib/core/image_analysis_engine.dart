import '../models/imaging_pipeline.dart';

class ImageAnalysisResult {
  final String status;
  final String? modelId;
  final double confidence;
  final Map<String, dynamic> findings;
  final String? reason;

  const ImageAnalysisResult({
    required this.status,
    this.modelId,
    required this.confidence,
    this.findings = const {},
    this.reason,
  });

  static ImageAnalysisResult unavailable(String reason) => ImageAnalysisResult(
        status: 'UNKNOWN',
        confidence: 0,
        reason: reason,
      );
}

abstract interface class ImageAnalysisModel {
  String get modelId;
  Set<SignalModality> get supportedModalities;
  bool get validated;
  Future<ImageAnalysisResult> analyze(ReconstructionResult image);
}

class ImageAnalysisEngine {
  final Map<SignalModality, ImageAnalysisModel> _models;

  ImageAnalysisEngine({Iterable<ImageAnalysisModel> models = const []})
      : _models = {for (final model in models) for (final modality in model.supportedModalities) modality: model};

  void register(ImageAnalysisModel model) {
    for (final modality in model.supportedModalities) {
      _models[modality] = model;
    }
  }

  Future<ImageAnalysisResult> analyze(ReconstructionResult image) async {
    if (!image.validated || image.volume.isEmpty) {
      return ImageAnalysisResult.unavailable('RECONSTRUCTION_NOT_VALIDATED');
    }
    final model = _models[image.modality];
    if (model == null) return ImageAnalysisResult.unavailable('AI_MODEL_UNAVAILABLE');
    if (!model.validated) return ImageAnalysisResult.unavailable('AI_MODEL_NOT_VALIDATED');
    return model.analyze(image);
  }
}
