import 'package:flutter_test/flutter_test.dart';
import 'package:ish_tissuemap_fusion/core/image_analysis_engine.dart';
import 'package:ish_tissuemap_fusion/models/imaging_pipeline.dart';

void main() {
  test('unvalidated reconstruction cannot reach AI', () async {
    final result = await ImageAnalysisEngine().analyze(
      ReconstructionResult.unavailable(SignalModality.mri, 'NOT_CONFIGURED'),
    );
    expect(result.status, 'UNKNOWN');
    expect(result.confidence, 0);
    expect(result.reason, 'RECONSTRUCTION_NOT_VALIDATED');
  });

  test('validated image without a registered model is explicit', () async {
    const image = ReconstructionResult(
      modality: SignalModality.optical,
      width: 2,
      height: 2,
      depth: 1,
      volume: [1, 2, 3, 4],
      uncertainty: [0, 0, 0, 0],
      unit: 'a.u.',
      validated: true,
    );
    final result = await ImageAnalysisEngine().analyze(image);
    expect(result.status, 'UNKNOWN');
    expect(result.reason, 'AI_MODEL_UNAVAILABLE');
  });
}
