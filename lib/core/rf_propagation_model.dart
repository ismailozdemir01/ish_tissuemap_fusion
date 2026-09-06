import 'dart:math' as math;

import '../models/rf_measurement.dart';

class RfPropagationFeature {
  final double frequencyMHz;
  final double distanceMeters;
  final double measuredRssiDbm;
  final double baselineRssiDbm;
  final double deltaRssiDb;
  final double pathLossResidualDb;
  final double quality;

  const RfPropagationFeature({required this.frequencyMHz, required this.distanceMeters, required this.measuredRssiDbm, required this.baselineRssiDbm, required this.deltaRssiDb, required this.pathLossResidualDb, required this.quality});
}

class RfPropagationModel {
  final double referenceDistanceMeters;
  final double pathLossExponent;

  const RfPropagationModel({this.referenceDistanceMeters = 1.0, this.pathLossExponent = 2.0}) : assert(referenceDistanceMeters > 0), assert(pathLossExponent > 0);

  RfPropagationFeature? evaluate({required RfMeasurement measurement, required double distanceMeters, required double baselineRssiDbm}) {
    final rssi = measurement.rssiDbm;
    final frequency = measurement.frequencyMHz;
    if (!measurement.isUsable || rssi == null || frequency == null || !distanceMeters.isFinite || distanceMeters <= 0 || !baselineRssiDbm.isFinite) return null;
    final expectedDelta = -10.0 * pathLossExponent * math.log(distanceMeters / referenceDistanceMeters) / math.ln10;
    final measuredDelta = rssi - baselineRssiDbm;
    return RfPropagationFeature(frequencyMHz: frequency, distanceMeters: distanceMeters, measuredRssiDbm: rssi, baselineRssiDbm: baselineRssiDbm, deltaRssiDb: measuredDelta, pathLossResidualDb: measuredDelta - expectedDelta, quality: measurement.quality);
  }
}
