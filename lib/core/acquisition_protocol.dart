import 'dart:convert';
import 'dart:typed_data';

import '../models/imaging_pipeline.dart';

class AcquisitionProtocolException implements Exception {
  final String message;
  const AcquisitionProtocolException(this.message);
  @override
  String toString() => 'AcquisitionProtocolException: $message';
}

/// Deterministic framed protocol shared by phone, acquisition hardware and PC.
/// Transport is intentionally separate: the same frame can travel over BLE, USB or Wi-Fi.
class AcquisitionFrameCodec {
  static const int _magic = 0x49534631; // ISF1
  static const int _headerLength = 12;

  const AcquisitionFrameCodec();

  Uint8List encode(List<RawSignalSample> samples) {
    final payload = utf8.encode(jsonEncode(samples.map((s) => {
      'sensorId': s.sensorId, 'modality': s.modality.name, 'timestampMicros': s.timestampMicros,
      'values': s.values, 'unit': s.unit, 'quality': s.quality,
    }).toList()));
    final crc = _crc32(payload);
    final out = ByteData(_headerLength + payload.length);
    out.setUint32(0, _magic, Endian.big);
    out.setUint32(4, payload.length, Endian.big);
    out.setUint32(8, crc, Endian.big);
    final bytes = out.buffer.asUint8List();
    bytes.setRange(_headerLength, bytes.length, payload);
    return bytes;
  }

  List<RawSignalSample> decode(Uint8List frame) {
    if (frame.length < _headerLength) throw const AcquisitionProtocolException('FRAME_TOO_SHORT');
    final header = ByteData.sublistView(frame);
    if (header.getUint32(0, Endian.big) != _magic) throw const AcquisitionProtocolException('BAD_MAGIC');
    final length = header.getUint32(4, Endian.big);
    if (length != frame.length - _headerLength) throw const AcquisitionProtocolException('BAD_LENGTH');
    final payload = frame.sublist(_headerLength);
    if (_crc32(payload) != header.getUint32(8, Endian.big)) throw const AcquisitionProtocolException('CRC_MISMATCH');
    final decoded = jsonDecode(utf8.decode(payload));
    if (decoded is! List) throw const AcquisitionProtocolException('BAD_PAYLOAD');
    return decoded.map((item) {
      if (item is! Map) throw const AcquisitionProtocolException('BAD_SAMPLE');
      final modalityName = item['modality'];
      final modality = SignalModality.values.where((m) => m.name == modalityName).firstOrNull;
      if (modality == null) throw const AcquisitionProtocolException('UNKNOWN_MODALITY');
      final values = item['values'];
      if (values is! List) throw const AcquisitionProtocolException('BAD_VALUES');
      return RawSignalSample(
        sensorId: item['sensorId'] as String,
        modality: modality,
        timestampMicros: (item['timestampMicros'] as num).toInt(),
        values: values.map((v) => (v as num).toDouble()).toList(growable: false),
        unit: item['unit'] as String,
        quality: (item['quality'] as num).toDouble(),
      );
    }).toList(growable: false);
  }

  int _crc32(List<int> data) {
    var crc = 0xffffffff;
    for (final byte in data) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (crc >>> 1) ^ 0xedb88320 : crc >>> 1;
      }
    }
    return crc ^ 0xffffffff;
  }
}
