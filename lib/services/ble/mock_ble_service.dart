import 'dart:async';
import 'dart:math';
import '../../data/models/device_model.dart';
import 'ble_service.dart';
import 'sensor_packet_parser.dart';

class MockBleService implements IBleService {
  final _statusController = StreamController<BleConnectionStatus>.broadcast();
  final _sensorDataController = StreamController<ParsedSensorData>.broadcast();

  BleConnectionStatus _currentStatus = BleConnectionStatus.disconnected;
  SmokeGuardDevice? _connectedDevice;
  bool _isCalibrated = true;
  Timer? _sensorDataTimer;
  final Random _random = Random();

  // Baseline sensor values for smooth simulation
  double _currentPm25 = 12.0;
  double _currentVoc = 45.0;
  double _currentTemp = 24.2;
  double _currentHum = 48.0;
  int _currentBattery = 92;

  MockBleService() {
    _statusController.add(_currentStatus);
  }

  @override
  BleConnectionStatus get currentStatus => _currentStatus;

  @override
  SmokeGuardDevice? get connectedDevice => _connectedDevice;

  @override
  bool get isCalibrated => _isCalibrated;

  @override
  Stream<BleConnectionStatus> get connectionStatusStream =>
      _statusController.stream;

  @override
  Stream<List<SmokeGuardDevice>> scanDevices() async* {
    yield [];
    await Future.delayed(const Duration(milliseconds: 600));

    final mockDevices = [
      const SmokeGuardDevice(
        id: 'dev_mock_001',
        name: 'SmokeGuard-V1 #4829',
        bluetoothId: 'SG:48:29:AA:BB:CC',
        batteryLevel: 92,
        connectionStatus: BleConnectionStatus.disconnected,
        isCalibrated: true,
        rssi: -58,
      ),
      const SmokeGuardDevice(
        id: 'dev_mock_002',
        name: 'SmokeGuard-V1 #1092',
        bluetoothId: 'SG:10:92:DD:EE:FF',
        batteryLevel: 74,
        connectionStatus: BleConnectionStatus.disconnected,
        isCalibrated: false,
        rssi: -74,
      ),
    ];

    yield mockDevices;
  }

  @override
  Future<void> stopScan() async {
    // No-op for mock
  }

  @override
  Future<void> connect(SmokeGuardDevice device) async {
    _currentStatus = BleConnectionStatus.connecting;
    _statusController.add(_currentStatus);

    await Future.delayed(const Duration(milliseconds: 800));

    _currentStatus = BleConnectionStatus.connected;
    _connectedDevice = device.copyWith(
      connectionStatus: BleConnectionStatus.connected,
      lastConnectedAt: DateTime.now(),
    );
    _statusController.add(_currentStatus);

    _startSensorDataSimulation();
  }

  @override
  Future<void> disconnect() async {
    _sensorDataTimer?.cancel();
    _currentStatus = BleConnectionStatus.disconnected;
    _connectedDevice = _connectedDevice?.copyWith(
      connectionStatus: BleConnectionStatus.disconnected,
    );
    _statusController.add(_currentStatus);
  }

  @override
  Stream<ParsedSensorData> subscribeToSensorData() {
    if (_currentStatus == BleConnectionStatus.connected && _sensorDataTimer == null) {
      _startSensorDataSimulation();
    }
    return _sensorDataController.stream;
  }

  @override
  Future<int> getBatteryLevel() async {
    return _currentBattery;
  }

  @override
  Stream<double> calibrateSensor() async* {
    // Emits progress from 0.0 to 1.0 over calibration duration
    const totalSteps = 60; // 60 seconds calibration
    for (int step = 1; step <= totalSteps; step++) {
      await Future.delayed(const Duration(milliseconds: 1000));
      final progress = step / totalSteps;
      yield progress;
    }
    _isCalibrated = true;
    if (_connectedDevice != null) {
      _connectedDevice = _connectedDevice!.copyWith(isCalibrated: true);
    }
  }

  void _startSensorDataSimulation() {
    _sensorDataTimer?.cancel();
    // Emit a reading every 2 seconds parsed through SensorPacketParser
    _sensorDataTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_currentStatus != BleConnectionStatus.connected) return;

      // Realistic smooth drift (not pure random)
      _currentPm25 += (_random.nextDouble() * 2 - 1);
      _currentPm25 = _currentPm25.clamp(5.0, 35.0);

      _currentVoc += (_random.nextDouble() * 4 - 2);
      _currentVoc = _currentVoc.clamp(20.0, 80.0);

      _currentTemp += (_random.nextDouble() * 0.2 - 0.1);
      _currentTemp = _currentTemp.clamp(20.0, 28.0);

      _currentHum += (_random.nextDouble() * 0.4 - 0.2);
      _currentHum = _currentHum.clamp(40.0, 60.0);

      // Encode using SensorPacketParser and decode to verify full pipeline
      final rawBytes = SensorPacketParser.encode(
        pm25: _currentPm25.round(),
        voc: _currentVoc.round(),
        temperature: _currentTemp,
        humidity: _currentHum,
        battery: _currentBattery,
      );

      final parsed = SensorPacketParser.parse(rawBytes);
      _sensorDataController.add(parsed);
    });
  }

  void dispose() {
    _sensorDataTimer?.cancel();
    _statusController.close();
    _sensorDataController.close();
  }
}
