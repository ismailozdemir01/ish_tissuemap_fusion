class TissuePoint {
  final double x;
  final double y;
  final double density;
  final double conductivity;
  final double timestamp;

  TissuePoint({
    required this.x,
    required this.y,
    required this.density,
    required this.conductivity,
    required this.timestamp,
  });

  double get fusionScore => (density * 1.5) + (conductivity * 0.8);

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'density': density,
        'conductivity': conductivity,
        'fusionScore': fusionScore,
        'timestamp': timestamp,
      };
}
