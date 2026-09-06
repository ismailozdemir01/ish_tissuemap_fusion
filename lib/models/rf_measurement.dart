enum RfAccessLevel {
  rssi,
  linkMetadata,
  csi,
  iq,
  phase,
  unavailable,
}

class RfMeasurement {
  const RfMeasurement({
    required this.timestampMicros,
    required this.accessLevel,
    this.frequencyMHz,
    this.channel,
    this.rssiDbm,
    this.txLinkMbps,
    this.rxLinkMbps,
    this.channelWidthMHz,
    this.quality = 0,
    this.reason,
  });

  final int timestampMicros;
  final RfAccessLevel accessLevel;
  final double? frequencyMHz;
  final int? channel;
  final double? rssiDbm;
  final double? txLinkMbps;
  final double? rxLinkMbps;
  final double? channelWidthMHz;
  final double quality;
  final String? reason;

  bool get isUsable =>
      accessLevel != RfAccessLevel.unavailable &&
      rssiDbm != null &&
      rssiDbm!.isFinite &&
      quality.isFinite &&
      quality > 0;

  Map<String, Object?> toJson() => {
        'timestampMicros': timestampMicros,
        'accessLevel': accessLevel.name,
        'frequencyMHz': frequencyMHz,
        'channel': channel,
        'rssiDbm': rssiDbm,
        'txLinkMbps': txLinkMbps,
        'rxLinkMbps': rxLinkMbps,
        'channelWidthMHz': channelWidthMHz,
        'quality': quality,
        'reason': reason,
      };
}
