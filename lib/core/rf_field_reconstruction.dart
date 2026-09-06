import 'dart:math' as math;

import 'rf_spatial_mapper.dart';

class RfFieldVoxel {
  final double x;
  final double y;
  final double z;
  final double attenuationDb;
  final double uncertaintyDb;
  final int contributingSamples;

  const RfFieldVoxel({
    required this.x,
    required this.y,
    required this.z,
    required this.attenuationDb,
    required this.uncertaintyDb,
    required this.contributingSamples,
  });
}

class RfFieldResult {
  final List<RfFieldVoxel> voxels;
  final bool volumetric;
  final String status;
  final String? reason;

  const RfFieldResult({required this.voxels, required this.volumetric, required this.status, this.reason});
}

/// Reconstructs a measured RF attenuation field from real handset RSSI observations.
/// It deliberately does not label scalar RSSI output as anatomical CT/MRI imagery.
class RfFieldReconstruction {
  final int gridSize;
  final double minimumQuality;

  const RfFieldReconstruction({this.gridSize = 12, this.minimumQuality = 0.25});

  RfFieldResult reconstruct(RfSpatialMapper mapper) {
    final points = mapper.points.where((p) => p.quality >= minimumQuality).toList();
    final base = mapper.baseline();
    if (points.length < 5 || base == null) {
      return const RfFieldResult(
        voxels: [], volumetric: false, status: 'UNKNOWN',
        reason: 'INSUFFICIENT_RF_OBSERVABILITY_OR_BASELINE',
      );
    }

    double minValue(Iterable<double> values) => values.reduce((a, b) => a < b ? a : b);
    double maxValue(Iterable<double> values) => values.reduce((a, b) => a > b ? a : b);
    final minX = minValue(points.map((p) => p.x));
    final maxX = maxValue(points.map((p) => p.x));
    final minY = minValue(points.map((p) => p.y));
    final maxY = maxValue(points.map((p) => p.y));
    final minZ = minValue(points.map((p) => p.z));
    final maxZ = maxValue(points.map((p) => p.z));

    final voxels = <RfFieldVoxel>[];
    for (var ix = 0; ix < gridSize; ix++) {
      for (var iy = 0; iy < gridSize; iy++) {
        for (var iz = 0; iz < gridSize; iz++) {
          final x = _grid(ix, minX, maxX);
          final y = _grid(iy, minY, maxY);
          final z = _grid(iz, minZ, maxZ);
          var weighted = 0.0;
          var weightSum = 0.0;
          var uncertainty = 0.0;
          var count = 0;
          for (final point in points) {
            if ((point.frequencyMHz - points.first.frequencyMHz).abs() > 1e-6) continue;
            final d = math.sqrt(math.pow(point.x - x, 2) + math.pow(point.y - y, 2) + math.pow(point.z - z, 2));
            final weight = point.quality / (d + 0.01);
            final attenuation = base - point.rssiDbm;
            weighted += attenuation * weight;
            weightSum += weight;
            uncertainty += point.uncertaintyDb * weight;
            count++;
          }
          if (weightSum > 0) {
            voxels.add(RfFieldVoxel(
              x: x, y: y, z: z,
              attenuationDb: weighted / weightSum,
              uncertaintyDb: uncertainty / weightSum,
              contributingSamples: count,
            ));
          }
        }
      }
    }

    return RfFieldResult(
      voxels: voxels,
      volumetric: false,
      status: voxels.isEmpty ? 'UNKNOWN' : 'RF_FIELD_READY',
      reason: voxels.isEmpty ? 'NO_RECONSTRUCTABLE_RF_FIELD' : 'RSSI_SPATIAL_FIELD_ONLY',
    );
  }

  double _grid(int index, double min, double max) =>
      gridSize <= 1 ? min : min + (max - min) * index / (gridSize - 1);
}
