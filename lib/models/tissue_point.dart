class TissuePoint {
  final double x;          // Telefonun yatay konumu (simule/gyro)
  final double y;          // Telefonun dikey konumu
  final double density;    // 0.0 (sıvı) - 1.0 (katı/kemik)
  final double conductivity; // 0.0 (yüksek direnç) - 1.0 (düşük direnç)
  final double timestamp;

  TissuePoint({
    required this.x,
    required this.y,
    required this.density,
    required this.conductivity,
    required this.timestamp,
  });

  // Hibrit Füzyon Skoru: Yüksek = Anormallik (Tümör/Kist/Ödem)
  double get fusionScore {
    // Yoğunluk yüksek + İletkenlik yüksek = İltihap/Ödem
    // Yoğunluk çok yüksek + İletkenlik çok düşük = Kalsifikasyon/Tümör
    return (density * 1.5) + (conductivity * 0.8);
  }

  Map<String, dynamic> toJson() => {
    'x': x, 'y': y, 'density': density,
    'conductivity': conductivity, 'fusionScore': fusionScore
  };
}
