import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/device_model.dart';
import '../../services/ble/ble_provider.dart';
import '../../services/ble/ble_service.dart';

class DeviceState {
  final bool isScanning;
  final List<SmokeGuardDevice> discoveredDevices;
  final SmokeGuardDevice? connectedDevice;
  final BleConnectionStatus connectionStatus;
  final double calibrationProgress; // 0.0 to 1.0
  final bool isCalibrating;
  final String? errorMessage;

  const DeviceState({
    this.isScanning = false,
    this.discoveredDevices = const [],
    this.connectedDevice,
    this.connectionStatus = BleConnectionStatus.disconnected,
    this.calibrationProgress = 0.0,
    this.isCalibrating = false,
    this.errorMessage,
  });

  DeviceState copyWith({
    bool? isScanning,
    List<SmokeGuardDevice>? discoveredDevices,
    SmokeGuardDevice? connectedDevice,
    BleConnectionStatus? connectionStatus,
    double? calibrationProgress,
    bool? isCalibrating,
    String? errorMessage,
  }) {
    return DeviceState(
      isScanning: isScanning ?? this.isScanning,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      calibrationProgress: calibrationProgress ?? this.calibrationProgress,
      isCalibrating: isCalibrating ?? this.isCalibrating,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DeviceController extends StateNotifier<DeviceState> {
  final IBleService _bleService;
  StreamSubscription<List<SmokeGuardDevice>>? _scanSub;
  StreamSubscription<BleConnectionStatus>? _statusSub;
  StreamSubscription<double>? _calibSub;

  DeviceController(this._bleService) : super(const DeviceState()) {
    _statusSub = _bleService.connectionStatusStream.listen((status) {
      state = state.copyWith(
        connectionStatus: status,
        connectedDevice: _bleService.connectedDevice,
      );
    });
  }

  void startScan() {
    state = state.copyWith(isScanning: true, discoveredDevices: [], errorMessage: null);

    _scanSub?.cancel();
    _scanSub = _bleService.scanDevices().listen(
      (devices) {
        state = state.copyWith(discoveredDevices: devices);
      },
      onError: (err) {
        state = state.copyWith(isScanning: false, errorMessage: err.toString());
      },
      onDone: () {
        state = state.copyWith(isScanning: false);
      },
    );
  }

  Future<void> stopScan() async {
    await _bleService.stopScan();
    _scanSub?.cancel();
    state = state.copyWith(isScanning: false);
  }

  Future<void> connect(SmokeGuardDevice device) async {
    try {
      await stopScan();
      state = state.copyWith(errorMessage: null);
      await _bleService.connect(device);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> disconnect() async {
    await _bleService.disconnect();
    state = state.copyWith(
      connectedDevice: null,
      connectionStatus: BleConnectionStatus.disconnected,
    );
  }

  void startCalibration() {
    if (state.isCalibrating) return;

    state = state.copyWith(
      isCalibrating: true,
      calibrationProgress: 0.0,
      errorMessage: null,
    );

    _calibSub?.cancel();
    _calibSub = _bleService.calibrateSensor().listen(
      (progress) {
        state = state.copyWith(calibrationProgress: progress);
      },
      onError: (err) {
        state = state.copyWith(isCalibrating: false, errorMessage: err.toString());
      },
      onDone: () {
        state = state.copyWith(
          isCalibrating: false,
          calibrationProgress: 1.0,
          connectedDevice: state.connectedDevice?.copyWith(isCalibrated: true),
        );
      },
    );
  }

  void cancelCalibration() {
    _calibSub?.cancel();
    state = state.copyWith(isCalibrating: false, calibrationProgress: 0.0);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _statusSub?.cancel();
    _calibSub?.cancel();
    super.dispose();
  }
}

final deviceControllerProvider =
    StateNotifierProvider<DeviceController, DeviceState>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return DeviceController(bleService);
});
