import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../models/rf_measurement.dart';

/// Reads only RF telemetry that the handset OS/firmware actually exposes.
/// It never synthesizes CSI/IQ/phase values when the platform does not expose them.
class WifiRfService {
  WifiRfService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('ish_tissuemap_fusion/rf');

  final MethodChannel _channel;
  Timer? _timer;
  final StreamController<RfMeasurement> _controller = StreamController.broadcast();

  Stream<RfMeasurement> get measurements => _controller.stream;

  Future<RfMeasurement> sample() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return _unavailable('RF_PLATFORM_UNSUPPORTED');
    }
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('readWifiRf');
      if (raw == null) return _unavailable('RF_TELEMETRY_UNAVAILABLE');
      final access = _parseAccess(raw['accessLevel']?.toString());
      final measurement = RfMeasurement(
        timestampMicros: (raw['timestampMicros'] as num?)?.toInt() ?? DateTime.now().microsecondsSinceEpoch,
        accessLevel: access,
        frequencyMHz: (raw['frequencyMHz'] as num?)?.toDouble(),
        channel: (raw['channel'] as num?)?.toInt(),
        rssiDbm: (raw['rssiDbm'] as num?)?.toDouble(),
        txLinkMbps: (raw['txLinkMbps'] as num?)?.toDouble(),
        rxLinkMbps: (raw['rxLinkMbps'] as num?)?.toDouble(),
        channelWidthMHz: (raw['channelWidthMHz'] as num?)?.toDouble(),
        quality: ((raw['quality'] as num?)?.toDouble() ?? 0).clamp(0, 1).toDouble(),
        reason: raw['reason']?.toString(),
      );
      _controller.add(measurement);
      return measurement;
    } on MissingPluginException {
      return _unavailable('RF_NATIVE_BRIDGE_NOT_IMPLEMENTED');
    } on PlatformException catch (error) {
      return _unavailable('RF_NATIVE_ERROR:${error.code}');
    }
  }

  void start({Duration interval = const Duration(milliseconds: 100)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      sample();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    stop();
    await _controller.close();
  }

  RfMeasurement _unavailable(String reason) {
    final measurement = RfMeasurement(
      timestampMicros: DateTime.now().microsecondsSinceEpoch,
      accessLevel: RfAccessLevel.unavailable,
      quality: 0,
      reason: reason,
    );
    _controller.add(measurement);
    return measurement;
  }

  RfAccessLevel _parseAccess(String? value) {
    switch (value) {
      case 'rssi':
        return RfAccessLevel.rssi;
      case 'linkMetadata':
        return RfAccessLevel.linkMetadata;
      case 'csi':
        return RfAccessLevel.csi;
      case 'iq':
        return RfAccessLevel.iq;
      case 'phase':
        return RfAccessLevel.phase;
      default:
        return RfAccessLevel.unavailable;
    }
  }
}
