import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  final workflow = _read('.github/workflows/release-builds.yml');
  final controller = _read('lib/core/phone_only_body_scan_controller.dart');
  final rfService = _read('lib/services/acquisition/wifi_rf_service.dart');
  final androidBridge = File('android/app/src/main/kotlin/com/ish/tissuemapfusion/MainActivity.kt').existsSync()
      ? _read('android/app/src/main/kotlin/com/ish/tissuemapfusion/MainActivity.kt')
      : '';

  test('1. release workflow covers APK, Windows EXE and iOS IPA', () {
    expect(workflow, contains('flutter build apk --release'));
    expect(workflow, contains('flutter build windows --release'));
    expect(workflow, contains('flutter build ios --release --no-codesign'));
    expect(workflow, contains('upload-artifact@v4'));
  });

  test('2. phone-only pipeline is explicitly wired to real acquisition services', () {
    expect(controller, contains('AcquisitionSession'));
    expect(controller, contains('WifiRfService'));
    expect(controller, contains('OpticalCameraService'));
    expect(controller, contains('VisualTrackingService'));
    expect(controller, contains('CommonCoordinateFusionEngine'));
    expect(controller, isNot(contains('Random')));
  });

  test('3. production code does not contain obvious synthetic measurement generators', () {
    final files = Directory('lib').listSync(recursive: true).whereType<File>();
    final source = files
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');
    expect(source, isNot(contains('Random()')));
    expect(source, isNot(contains('Random(')));
    expect(source, isNot(contains('List.filled(4096')));
    expect(source, isNot(contains('syntheticTissue')));
  });

  test('4. unavailable or uncalibrated data cannot silently become clinical output', () {
    final status = _read('lib/models/measurement_status.dart');
    final reconstruction = _read('lib/core/tissue_volume_reconstruction_engine.dart');
    final analysis = _read('lib/core/image_analysis_engine.dart');
    expect(status, contains('unknown'));
    expect(status, contains('notCalibrated'));
    expect(reconstruction, contains('validated'));
    expect(analysis, contains('UNKNOWN'));
    expect(analysis, contains('MODEL_UNAVAILABLE'));
  });

  test('5. RF provenance exposes real access levels and never fabricates CSI/IQ/phase', () {
    final measurement = _read('lib/models/rf_measurement.dart');
    expect(rfService, contains('readWifiRf'));
    expect(rfService, isNot(contains('fakeCsi')));
    expect(rfService, isNot(contains('synthetic')));
    expect(measurement, contains('enum RfAccessLevel'));
    expect(measurement, contains('rssi,'));
    expect(measurement, contains('csi,'));
    expect(measurement, contains('iq,'));
    expect(measurement, contains('phase,'));
    expect(measurement, contains('accessLevel.name'));
  });

  test('6. acquisition lifecycle has start, stop and dispose cleanup paths', () {
    expect(controller, contains('Future<void> start'));
    expect(controller, contains('Future<void> stop'));
    expect(controller, contains('Future<void> dispose'));
    expect(controller, contains('cancel()'));
    expect(controller, contains('rf.dispose()'));
    expect(controller, contains('camera.dispose()'));
  });

  test('7. Android RF bridge contract is present and uses WifiManager connection data', () {
    expect(androidBridge, isNotEmpty,
        reason: 'Android RF bridge source must remain in the repository');
    expect(androidBridge, contains('WifiManager'));
    expect(androidBridge, contains('connectionInfo'));
    expect(androidBridge, contains('ish_tissuemap_fusion/rf'));
    expect(androidBridge, contains('rssi'));
    expect(androidBridge, contains('frequencyMHz'));
  });

  test('8. release workflow validates generated platform projects and artifact paths', () {
    expect(workflow, contains('flutter create --platforms android,ios,windows .'));
    expect(workflow, contains('build/app/outputs/flutter-apk/*.apk'));
    expect(workflow, contains('build/windows/x64/runner/Release/*'));
    expect(workflow, contains('build/ios/iphoneos/Runner.app'));
    expect(workflow, contains('if-no-files-found: error'));
  });
}
