import 'dart:math' as math;

/// Regular 3-D reconstruction grid expressed in the phone scan coordinate
/// system. It contains geometry only; it never assigns tissue values.
class RfVoxelGrid3D {
  final double minX;
  final double minY;
  final double minZ;
  final double maxX;
  final double maxY;
  final double maxZ;
  final double spacingMeters;

  const RfVoxelGrid3D({
    required this.minX,
    required this.minY,
    required this.minZ,
    required this.maxX,
    required this.maxY,
    required this.maxZ,
    required this.spacingMeters,
  });

  bool get valid => spacingMeters.isFinite && spacingMeters > 0 && minX.isFinite && minY.isFinite && minZ.isFinite && maxX.isFinite && maxY.isFinite && maxZ.isFinite && maxX >= minX && maxY >= minY && maxZ >= minZ;

  int get width => valid ? ((maxX - minX) / spacingMeters).floor() + 1 : 0;
  int get height => valid ? ((maxY - minY) / spacingMeters).floor() + 1 : 0;
  int get depth => valid ? ((maxZ - minZ) / spacingMeters).floor() + 1 : 0;
  int get voxelCount => width * height * depth;

  List<List<double>> get centers {
    if (!valid) return const [];
    final result = <List<double>>[];
    for (var z = 0; z < depth; z++) {
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          result.add([minX + x * spacingMeters, minY + y * spacingMeters, minZ + z * spacingMeters]);
        }
      }
    }
    return result;
  }

  int index(int x, int y, int z) {
    if (x < 0 || y < 0 || z < 0 || x >= width || y >= height || z >= depth) throw RangeError('Voxel index outside grid');
    return z * width * height + y * width + x;
  }

  List<int> nearestIndex(double x, double y, double z) {
    if (!valid) throw StateError('Invalid voxel grid');
    int nearest(double value, double min, int count) => math.max(0, math.min(count - 1, ((value - min) / spacingMeters).round()));
    return [nearest(x, minX, width), nearest(y, minY, height), nearest(z, minZ, depth)];
  }
}
