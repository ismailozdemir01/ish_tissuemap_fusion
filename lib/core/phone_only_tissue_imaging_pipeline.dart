import '../models/body_scan.dart';
import '../models/measurement_status.dart';
import '../models/rf_measurement.dart';
import '../models/tissue_volume.dart';
import 'rf_voxel_grid.dart';
import 'tissue_volume_reconstruction_engine.dart';

/// End-to-end phone-only reconstruction boundary.
///
/// The only production observations accepted here are RF measurements that
/// were physically acquired by the phone and registered to the phone pose.
/// Camera/inertial data provide registration constraints; they are never
/// converted into invented internal tissue values.
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

    final rfSamples = acquisition.where((sample) =>
        sample.signal.modality.name == 'radioFrequency' &&
        sample.signal.values.isNotEmpty &&
        sample.signal.values.first.isFinite &&
        sample.pose.x.isFinite && sample.pose.y.isFinite && sample.pose.z.isFinite &&
        sample.signal.quality > 0);

    final samples = rfSamples.toList();
    if (samples.isEmpty) {
      return TissueVolume3D.unknown(reason: 'NO_REAL_PHONE_RF_OBSERVATIONS');
    }

    final frequencies = <double>[];
    final measurements = <List<double>>[];
    final observations = <double>[];
    final weights = <double>[];

    for (final sample in samples) {
      final frequency = _frequencyFromSample(sample);
      if (frequency == null) continue;
      frequencies.add(frequency);
      measurements.add([sample.pose.x, sample.pose.y, sample.pose.z]);
      observations.add(sample.signal.values.first);
      weights.add(sample.signal.quality.clamp(0.001, 1.0).toDouble());
    }

    if (observations.isEmpty) {
      return TissueVolume3D.unknown(reason: 'NO_VALID_PHONE_RF_GEOMETRY');
    }

    return reconstruction.reconstruct(
      model: model,
      frequenciesMHz: frequencies,
      voxelCoordinates: grid.centers,
      measurementCoordinates: measurements,
      observations: observations,
      weights: weights,
      width: grid.width,
      height: grid.height,
      depth: grid.depth,
    );
  }

  double? _frequencyFromSample(SpatialAcquisitionSample sample) {
    // The acquisition sample currently carries dBm but not RF metadata.
    // Reject rather than invent a frequency. Frequency-aware reconstruction
    // must receive the original RfMeasurement metadata in a future adapter.
    return null;
  }
}
