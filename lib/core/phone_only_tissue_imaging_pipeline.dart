import '../models/body_scan.dart';
import '../models/imaging_pipeline.dart';
import '../models/tissue_volume.dart';
import 'rf_voxel_grid.dart';
import 'tissue_volume_reconstruction_engine.dart';

/// End-to-end phone-only reconstruction boundary.
///
/// RF observations are physically acquired by the phone and registered to
/// the phone pose. Camera/inertial data provide registration constraints;
/// they are never converted into invented internal tissue values.
class PhoneOnlyTissueImagingPipeline {
  final TissueVolumeReconstructionEngine reconstruction;

  const PhoneOnlyTissueImagingPipeline({
    this.reconstruction = const TissueVolumeReconstructionEngine(),
  });

  TissueVolume3D reconstruct({
    required Iterable<SpatialAcquisitionSample> acquisition,
    required RfVoxelGrid3D grid,
    required ValidatedTissueForwardModel model,
  }) {
    if (!grid.valid || grid.voxelCount == 0) {
      return TissueVolume3D.unknown(reason: 'INVALID_PHONE_SCAN_VOXEL_GRID');
    }
    if (!model.validated) {
      return TissueVolume3D.unknown(reason: 'TISSUE_FORWARD_MODEL_NOT_VALIDATED');
    }

    final samples = acquisition.where((sample) =>
        sample.signal.modality == SignalModality.radioFrequency &&
        sample.signal.values.isNotEmpty &&
        sample.signal.values.first.isFinite &&
        sample.signal.frequencyMHz != null &&
        sample.signal.frequencyMHz!.isFinite &&
        sample.signal.frequencyMHz! > 0 &&
        sample.pose.x.isFinite && sample.pose.y.isFinite && sample.pose.z.isFinite &&
        sample.signal.quality > 0).toList();

    if (samples.isEmpty) {
      return TissueVolume3D.unknown(reason: 'NO_REAL_PHONE_RF_OBSERVATIONS');
    }

    final frequencies = <double>[];
    final measurementCoordinates = <List<double>>[];
    final observations = <double>[];
    final weights = <double>[];

    for (final sample in samples) {
      frequencies.add(sample.signal.frequencyMHz!);
      measurementCoordinates.add([sample.pose.x, sample.pose.y, sample.pose.z]);
      observations.add(sample.signal.values.first);
      weights.add(sample.signal.quality.clamp(0.001, 1.0).toDouble());
    }

    return reconstruction.reconstruct(
      model: model,
      frequenciesMHz: frequencies,
      voxelCoordinates: grid.centers,
      measurementCoordinates: measurementCoordinates,
      observations: observations,
      weights: weights,
      width: grid.width,
      height: grid.height,
      depth: grid.depth,
    );
  }
}
