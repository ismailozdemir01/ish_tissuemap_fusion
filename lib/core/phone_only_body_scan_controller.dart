import 'dart:async';
import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../models/body_scan.dart';
import '../models/imaging_pipeline.dart';
import '../models/rf_measurement.dart';
import '../models/optical_frame.dart';
import '../models/registered_optical_frame.dart';
import '../services/acquisition/optical_camera_service.dart';
import '../services/acquisition/visual_tracking_service.dart';
import '../services/acquisition/wifi_rf_service.dart';
import 'acquisition_session.dart';
import 'body_scan_engine.dart';
import 'common_coordinate_fusion_engine.dart';
import 'optical_registration_engine.dart';
import 'phone_sensor_adapters.dart';
import 'pose_history.dart';
import 'rf_spatial_mapper.dart';

class PhoneOnlyBodyScanController {
  PhoneOnlyBodyScanController({AcquisitionSession? acquisition, WifiRfService? rf, OpticalCameraService? camera, VisualTrackingService? visualTracking, BodyScanEngine? bodyScan, RfSpatialMapper? rfMapper, PoseHistory? poseHistory, OpticalRegistrationEngine? opticalRegistration, CommonCoordinateFusionEngine? coordinateFusion}) {
    this.acquisition = acquisition ?? AcquisitionSession(sensors: PhoneSensorRegistry.defaults().sensors);
    this.rf = rf ?? WifiRfService();
    this.camera = camera ?? OpticalCameraService();
    this.visualTracking = visualTracking ?? VisualTrackingService();
    this.bodyScan = bodyScan ?? BodyScanEngine(minimumPoseQuality: 0.25);
    this.rfMapper = rfMapper ?? RfSpatialMapper();
    this.poseHistory = poseHistory ?? PoseHistory();
    this.opticalRegistration = opticalRegistration ?? const OpticalRegistrationEngine();
    this.coordinateFusion = coordinateFusion ?? CommonCoordinateFusionEngine(poseHistory: this.poseHistory, rfMapper: this.rfMapper);
  }

  late final AcquisitionSession acquisition;
  late final WifiRfService rf;
  late final OpticalCameraService camera;
  late final VisualTrackingService visualTracking;
  late final BodyScanEngine bodyScan;
  late final RfSpatialMapper rfMapper;
  late final PoseHistory poseHistory;
  late final OpticalRegistrationEngine opticalRegistration;
  late final CommonCoordinateFusionEngine coordinateFusion;

  final StreamController<SpatialAcquisitionSample> _samples = StreamController.broadcast();
  final StreamController<OpticalFrame> _frames = StreamController.broadcast();
  final StreamController<RegisteredOpticalFrame> _registeredFrames = StreamController.broadcast();
  final StreamController<VisualTrackingResult> _visualResults = StreamController.broadcast();
  StreamSubscription<RawSignalSample>? _sensorSubscription;
  StreamSubscription<RfMeasurement>? _rfSubscription;
  ScanPose _pose = const ScanPose(timestampMicros: 0, x: 0, y: 0, z: 0, qx: 0, qy: 0, qz: 0, qw: 1, quality: 0);
  Vector3 _velocity = Vector3.zero();
  Quaternion _orientation = Quaternion.identity();
  Vector3? _lastAcceleration;
  int? _lastGyroMicros;
  int? _lastAccelerationMicros;
  int? _startedAtMicros;
  bool _running = false;
  BodyRegion? _region;

  Stream<SpatialAcquisitionSample> get samples => _samples.stream;
  Stream<OpticalFrame> get frames => _frames.stream;
  Stream<RegisteredOpticalFrame> get registeredFrames => _registeredFrames.stream;
  Stream<VisualTrackingResult> get visualResults => _visualResults.stream;
  bool get running => _running;
  ScanPose get pose => _pose;
  ScanCoverage get coverage => bodyScan.coverage();
  CommonCoordinateFusionState get coordinateState => coordinateFusion.state;

  Future<void> start({BodyRegion? region, bool initializeCamera = true}) async {
    if (_running) return;
    _region = region;
    _startedAtMicros = DateTime.now().microsecondsSinceEpoch;
    _pose = ScanPose(timestampMicros: _startedAtMicros!, x: 0, y: 0, z: 0, qx: 0, qy: 0, qz: 0, qw: 1, quality: 0);
    _velocity = Vector3.zero();
    _orientation = Quaternion.identity();
    _lastAcceleration = null;
    _lastGyroMicros = null;
    _lastAccelerationMicros = null;
    poseHistory.clear();
    coordinateFusion.reset(anchor: _pose);
    try {
      visualTracking.start();
      if (initializeCamera) {
        try {
          await camera.initialize();
        } catch (_) {}
      }
      _running = true;
      _sensorSubscription = acquisition.samples.listen(_onSensorSample);
      _rfSubscription = rf.measurements.listen(_onRfMeasurement);
      await acquisition.start();
      rf.start();
      await Future<void>.delayed(Duration.zero);
    } catch (_) {
      await stop();
      rethrow;
    }
  }

  Future<OpticalFrame?> captureOpticalFrame() async {
    if (!_running || !camera.initialized) return null;
    try {
      final frame = await camera.capture();
      _frames.add(frame);
      final registered = opticalRegistration.register(frame, poseHistory, poseUncertainty: _poseUncertainty(_pose));
      if (registered != null) _registeredFrames.add(registered);
      final tracking = await visualTracking.process(frame);
      _visualResults.add(tracking);
      if (tracking.motion != null) coordinateFusion.addVisualMotion(tracking.motion!);
      return frame;
    } catch (_) {
      return null;
    }
  }

  Future<void> stop() async {
    _running = false;
    rf.stop();
    visualTracking.stop();
    await _sensorSubscription?.cancel();
    await _rfSubscription?.cancel();
    _sensorSubscription = null;
    _rfSubscription = null;
    await acquisition.stop();
  }

  Future<void> dispose() async {
    await stop();
    await acquisition.dispose();
    await rf.dispose();
    await camera.dispose();
    await _samples.close();
    await _frames.close();
    await _registeredFrames.close();
    await _visualResults.close();
  }

  void _onSensorSample(RawSignalSample sample) {
    if (!_running) return;
    if (sample.values.length < 3 || !sample.values.every((v) => v.isFinite)) return;
    if (sample.modality == SignalModality.inertial) _updatePose(sample);
    _emitSpatial(sample, pose: poseHistory.nearest(sample.timestampMicros) ?? _pose);
  }

  void _onRfMeasurement(RfMeasurement measurement) {
    if (!_running || !measurement.isUsable) return;
    final pose = poseHistory.interpolate(measurement.timestampMicros, minimumQuality: 0.25);
    if (pose == null || measurement.rssiDbm == null) return;
    coordinateFusion.addRfMeasurement(measurement);
    _emitSpatial(RawSignalSample(sensorId: 'phone.wifi.rf', modality: SignalModality.radioFrequency, timestampMicros: measurement.timestampMicros, values: [measurement.rssiDbm!], unit: 'dBm', quality: measurement.quality, frequencyMHz: measurement.frequencyMHz, channel: measurement.channel), pose: pose);
  }

  void _updatePose(RawSignalSample sample) {
    final now = sample.timestampMicros;
    if (sample.sensorId.contains('gyroscope')) {
      final previous = _lastGyroMicros;
      _lastGyroMicros = now;
      if (previous == null) return;
      final dt = (now - previous) / 1000000.0;
      if (dt <= 0 || dt > 0.25) return;
      final omega = Vector3.array(sample.values);
      final angle = omega.length * dt;
      if (angle.isFinite && angle > 0 && omega.length > 0) {
        _orientation = (_orientation * Quaternion.axisAngle(omega.normalized(), angle))..normalize();
        _updatePoseSnapshot(now);
      }
      return;
    }
    if (!sample.sensorId.contains('accelerometer')) return;
    final previous = _lastAccelerationMicros;
    _lastAccelerationMicros = now;
    final bodyAcceleration = Vector3.array(sample.values);
    if (previous == null) {
      _lastAcceleration = bodyAcceleration;
      _updatePoseSnapshot(now);
      return;
    }
    final dt = (now - previous) / 1000000.0;
    if (dt <= 0 || dt > 0.25) {
      _lastAcceleration = bodyAcceleration;
      return;
    }
    final worldAcceleration = _orientation.rotated(bodyAcceleration);
    final linear = worldAcceleration - Vector3(0, 0, 9.80665);
    final previousAcceleration = _lastAcceleration;
    _lastAcceleration = bodyAcceleration;
    if (previousAcceleration == null) return;
    final previousWorld = _orientation.rotated(previousAcceleration) - Vector3(0, 0, 9.80665);
    final acceleration = (linear + previousWorld) * 0.5;
    _velocity += acceleration * dt;
    _velocity *= math.exp(-1.8 * dt);
    final position = Vector3(_pose.x, _pose.y, _pose.z) + _velocity * dt;
    _pose = ScanPose(timestampMicros: now, x: position.x, y: position.y, z: position.z, qx: _orientation.x, qy: _orientation.y, qz: _orientation.z, qw: _orientation.w, quality: _poseQuality(now));
    poseHistory.add(_pose);
    coordinateFusion.addMeasuredPose(_pose);
  }

  void _updatePoseSnapshot(int timestampMicros) {
    _pose = ScanPose(timestampMicros: timestampMicros, x: _pose.x, y: _pose.y, z: _pose.z, qx: _orientation.x, qy: _orientation.y, qz: _orientation.z, qw: _orientation.w, quality: _poseQuality(timestampMicros));
    poseHistory.add(_pose);
    coordinateFusion.addMeasuredPose(_pose);
  }

  void _emitSpatial(RawSignalSample signal, {required ScanPose pose}) {
    final spatial = SpatialAcquisitionSample(signal: signal, pose: pose, region: _region);
    _samples.add(spatial);
    bodyScan.add(spatial);
  }

  double _poseQuality(int timestampMicros) {
    final start = _startedAtMicros ?? timestampMicros;
    final elapsed = math.max(0, timestampMicros - start) / 1000000.0;
    return (0.75 * math.exp(-elapsed / 12.0)).clamp(0.05, 0.75).toDouble();
  }

  double _poseUncertainty(ScanPose pose) {
    final start = _startedAtMicros ?? pose.timestampMicros;
    final elapsed = math.max(0, pose.timestampMicros - start) / 1000000.0;
    return 1.0 + elapsed * 0.5;
  }
}
