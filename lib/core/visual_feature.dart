/// A feature measured from a real camera frame.
/// Coordinates are image pixels; no depth or anatomy is implied.
class VisualFeature {
  final int x;
  final int y;
  final List<double> descriptor;
  final double response;

  const VisualFeature({
    required this.x,
    required this.y,
    required this.descriptor,
    required this.response,
  });

  bool get valid =>
      x >= 0 &&
      y >= 0 &&
      response.isFinite &&
      descriptor.isNotEmpty &&
      descriptor.every((v) => v.isFinite);
}

class VisualFeatureSet {
  final String framePath;
  final int timestampMicros;
  final int width;
  final int height;
  final List<VisualFeature> features;

  const VisualFeatureSet({
    required this.framePath,
    required this.timestampMicros,
    required this.width,
    required this.height,
    required this.features,
  });
}
