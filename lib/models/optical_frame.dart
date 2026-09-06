class OpticalFrame {
  final String path;
  final int timestampMicros;
  final int width;
  final int height;
  final String format;
  final String cameraId;

  const OpticalFrame({
    required this.path,
    required this.timestampMicros,
    required this.width,
    required this.height,
    required this.format,
    required this.cameraId,
  });
}
