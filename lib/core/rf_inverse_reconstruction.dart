import 'dart:math' as math;

import '../models/measurement_status.dart';
import 'rf_spatial_mapper.dart';

class RfInverseVoxel {
  final double x;
  final double y;
  final double z;
  final double valueDb;
  final double uncertaintyDb;

  const RfInverseVoxel({
    required this.x,
    required this.y,
    required this.z,
    required this.valueDb,
    required this.uncertaintyDb,
  });
}

class RfInverseReconstructionResult {
  final MeasurementStatus status;
  final List<RfInverseVoxel> voxels;
  final String reason;
  final bool anatomical;

  const RfInverseReconstructionResult({
    required this.status,
    required this.voxels,
    required this.reason,
    required this.anatomical,
  });

  static const unavailable = RfInverseReconstructionResult(
    status: MeasurementStatus.unknown,
    voxels: [],
    reason: 'RF_INVERSE_MODEL_NOT_VALIDATED_FOR_ANATOMICAL_RECONSTRUCTION',
    anatomical: false,
  );
}

/// Experimental inverse RF field reconstruction from real spatial RSSI points.
/// It estimates the measured RF field only; it does not infer tissue properties.
class RfInverseReconstruction {
  final int gridResolution;
  final double minimumQuality;

  const RfInverseReconstruction({
    this.gridResolution = 9,
    this.minimumQuality = 0.25,
  });

  RfInverseReconstructionResult reconstruct(List<RfSpatialPoint> points) {
    final valid = points.where((p) =>
        p.quality >= minimumQuality &&
        p.rssiDbm.isFinite &&
        p.x.isFinite && p.y.isFinite && p.z.isFinite).toList(growable: false);
    if (valid.length < 5) return RfInverseReconstructionResult.unavailable;

    final minX = valid.map((p) => p.x).reduce(math.min);
    final maxX = valid.map((p) => p.x).reduce(math.max);
    final minY = valid.map((p) => p.y).reduce(math.min);
    final maxY = valid.map((p) => p.y).reduce(math.max);
    final minZ = valid.map((p) => p.z).reduce(math.min);
    final maxZ = valid.map((p) => p.z).reduce(math.max);

    final voxels = <RfInverseVoxel>[];
    for (var ix = 0; ix < gridResolution; ix++) {
      for (var iy = 0; iy < gridResolution; iy++) {
        for (var iz = 0; iz < gridResolution; iz++) {
          final x = _axis(ix, minX, maxX);
          final y = _axis(iy, minY, maxY);
          final z = _axis(iz, minZ, maxZ);
          var weighted = 0.0;
          var weightSum = 0.0;
          for (final p in valid) {
            final d = math.sqrt(math.pow(x - p.x, 2) + math.pow(y - p.y, 2) + math.pow(z - p.z, 2));
            final w = p.quality / math.max(d, 0.001);
            weighted += p.rssiDbm * w;
            weightSum += w;
          }
          if (weightSum > 0) {
            final value = weighted / weightSum;
            final uncertainty = 1.0 / math.sqrt(weightSum);
            voxels.add(RfInverseVoxel(
              x: x, y: y, z: z, valueDb: value, uncertaintyDb: uncertainty,
            ));
          }
        }
      }
    }

    return RfInverseReconstructionResult(
      status: MeasurementStatus.unknown,
      voxels: List.unmodifiable(voxels),
      reason: 'RF_FIELD_RECONSTRUCTED_NO_VALIDATED_TISSUE_MODEL',
      anatomical: false,
    );
  }

  double _axis(int index, double min, double max) {
    if (gridResolution <= 1 || max == min) return min;
    return min + (max - min) * index / (gridResolution - 1);
  }
}
