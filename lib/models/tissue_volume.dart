import 'measurement_status.dart';
import 'tissue_reconstruction_quality.dart';

class TissueVoxel {
  final double x;
  final double y;
  final double z;
  final double value;
  final double uncertainty;

  const TissueVoxel({
    required this.x,
    required this.y,
    required this.z,
    required this.value,
    required this.uncertainty,
  });
}

class TissueVolume3D {
  final int width;
  final int height;
  final int depth;
  final List<TissueVoxel> voxels;
  final MeasurementStatus status;
  final bool anatomical;
  final String modelId;
  final String reason;
  final TissueReconstructionQuality quality;

  const TissueVolume3D({
    required this.width,
    required this.height,
    required this.depth,
    required this.voxels,
    required this.status,
    required this.anatomical,
    required this.modelId,
    required this.reason,
    required this.quality,
  });

  static TissueVolume3D unknown({String reason = 'TISSUE_MODEL_NOT_VALIDATED'}) => TissueVolume3D(
        width: 0,
        height: 0,
        depth: 0,
        voxels: const [],
        status: MeasurementStatus.unknown,
        anatomical: false,
        modelId: '',
        reason: reason,
        quality: TissueReconstructionQuality.unknown(reason: reason),
      );
}
