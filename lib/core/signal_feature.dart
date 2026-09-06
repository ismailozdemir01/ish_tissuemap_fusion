import '../models/imaging_pipeline.dart';

class SignalFeature {
  final String featureId;
  final SignalModality modality;
  final String sensorId;
  final int timestampMicros;
  final List<double> values;
  final String unit;
  final double quality;
  final double uncertainty;

  const SignalFeature({
    required this.featureId,
    required this.modality,
    required this.sensorId,
    required this.timestampMicros,
    required this.values,
    required this.unit,
    required this.quality,
    required this.uncertainty,
  });
}

class MultimodalFeatureSet {
  final int timestampMicros;
  final List<SignalFeature> features;

  const MultimodalFeatureSet({required this.timestampMicros, required this.features});

  Set<SignalModality> get modalities => features.map((f) => f.modality).toSet();
}
