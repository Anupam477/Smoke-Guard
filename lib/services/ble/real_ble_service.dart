import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../data/models/device_model.dart';
import 'ble_service.dart';
import 'sensor_packet_parser.dart';

class RealBleService implements IBleService {
  final _statusController = StreamController<BleConnectionStatus>.broadcast();
  final _sensorDataController = StreamController<ParsedSensorData>.broadcast();

  BleConnectionStatus _currentStatus = BleConnectionStatus.disconnected;
  SmokeGuardDevice? _connectedDevice;
  fbp.BluetoothDevice? _fbpDevice;
  fbp.BluetoothCharacteristic? _dataChar;
  StreamSubscription<List<int>>? _charSubscription;
  StreamSubscription<fbp.BluetoothConnectionState>? _deviceConnSub;

  bool _isCalibrated = false;
  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;

  RealBleService() {
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

  Future<void> _checkPermissionsAndBluetooth() async {
    final btStatus = await fbp.FlutterBluePlus.adapterState.first;
    if (btStatus != fbp.BluetoothAdapterState.on) {
      throw BluetoothFailure.off();
    }

    // Android 12+ and general Bluetooth permissions
    final scanPerm = await Permission.bluetoothScan.request();
    final connPerm = await Permission.bluetoothConnect.request();
    final locPerm = await Permission.locationWhenInUse.request();

    if (scanPerm.isDenied || connPerm.isDenied) {
      throw BluetoothFailure.permissionDenied();
    }
  }

  @override
  Stream<List<SmokeGuardDevice>> scanDevices() async* {
    await _checkPermissionsAndBluetooth();

    // Start scanning with service UUID filter
    await fbp.FlutterBluePlus.startScan(
      withServices: [fbp.Guid(AppConstants.bleServiceUuid)],
      timeout: const Duration(seconds: 10),
    );

    yield* fbp.FlutterBluePlus.scanResults.map((results) {
      return results.map((r) {
        return SmokeGuardDevice(
          id: r.device.remoteId.str,
          name: r.device.platformName.isNotEmpty
              ? r.device.platformName
              : (r.advertisementData.advName.isNotEmpty
                  ? r.advertisementData.advName
                  : 'SmokeGuard Wearable'),
          bluetoothId: r.device.remoteId.str,
          rssi: r.rssi,
          connectionStatus: BleConnectionStatus.disconnected,
        );
      }).toList();
    });
  }

  @override
  Future<void> stopScan() async {
    await fbp.FlutterBluePlus.stopScan();
  }

  @override
  Future<void> connect(SmokeGuardDevice device) async {
    _intentionalDisconnect = false;
    _currentStatus = BleConnectionStatus.connecting;
    _statusController.add(_currentStatus);

    try {
      _fbpDevice = fbp.BluetoothDevice.fromId(device.bluetoothId);

      _deviceConnSub?.cancel();
      _deviceConnSub = _fbpDevice!.connectionState.listen((state) {
        if (state == fbp.BluetoothConnectionState.connected) {
          _currentStatus = BleConnectionStatus.connected;
          _reconnectAttempts = 0;
          _statusController.add(_currentStatus);
        } else if (state == fbp.BluetoothConnectionState.disconnected) {
          if (!_intentionalDisconnect) {
            _handleAutoReconnect(device);
          } else {
            _currentStatus = BleConnectionStatus.disconnected;
            _statusController.add(_currentStatus);
          }
        }
      });

      await _fbpDevice!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      _connectedDevice = device.copyWith(
        connectionStatus: BleConnectionStatus.connected,
        lastConnectedAt: DateTime.now(),
      );

      // Discover Services & Characteristics
      final services = await _fbpDevice!.discoverServices();
      for (final s in services) {
        if (s.uuid == fbp.Guid(AppConstants.bleServiceUuid)) {
          for (final c in s.characteristics) {
            if (c.uuid == fbp.Guid(AppConstants.bleDataCharUuid)) {
              _dataChar = c;
              await _dataChar!.setNotifyValue(true);
              _charSubscription?.cancel();
              _charSubscription = _dataChar!.onValueReceived.listen((bytes) {
                if (bytes.isNotEmpty) {
                  try {
                    final parsed = SensorPacketParser.parse(bytes);
                    _sensorDataController.add(parsed);
                  } catch (e) {
                    debugPrint('[RealBleService] Error parsing packet: $e');
                  }
                }
              });
            }
          }
        }
      }
    } catch (e) {
      _currentStatus = BleConnectionStatus.disconnected;
      _statusController.add(_currentStatus);
      throw BluetoothFailure.sensorError(e.toString());
    }
  }

  Future<void> _handleAutoReconnect(SmokeGuardDevice device) async {
    if (_intentionalDisconnect) return;

    _reconnectAttempts++;
    if (_reconnectAttempts > 5) {
      _currentStatus = BleConnectionStatus.disconnected;
      _statusController.add(_currentStatus);
      return;
    }

    _currentStatus = BleConnectionStatus.reconnecting;
    _statusController.add(_currentStatus);

    // Exponential backoff: 2s, 4s, 8s, 16s...
    final backoffSeconds = pow(2, _reconnectAttempts).toInt().clamp(2, 20);
    debugPrint('[RealBleService] Reconnecting in $backoffSeconds seconds (Attempt $_reconnectAttempts)...');
    await Future.delayed(Duration(seconds: backoffSeconds));

    try {
      await connect(device);
    } catch (_) {
      // Retried by connectionState listener
    }
  }

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _charSubscription?.cancel();
    _deviceConnSub?.cancel();
    if (_fbpDevice != null) {
      await _fbpDevice!.disconnect();
    }
    _currentStatus = BleConnectionStatus.disconnected;
    _connectedDevice = _connectedDevice?.copyWith(
      connectionStatus: BleConnectionStatus.disconnected,
    );
    _statusController.add(_currentStatus);
  }

  @override
  Stream<ParsedSensorData> subscribeToSensorData() {
    return _sensorDataController.stream;
  }

  @override
  Future<int> getBatteryLevel() async {
    return _connectedDevice?.batteryLevel ?? 100;
  }

  @override
  Stream<double> calibrateSensor() async* {
    const totalSteps = 60;
    for (int step = 1; step <= totalSteps; step++) {
      await Future.delayed(const Duration(seconds: 1));
      yield step / totalSteps;
    }
    _isCalibrated = true;
  }

  void dispose() {
    _charSubscription?.cancel();
    _deviceConnSub?.cancel();
    _statusController.close();
    _sensorDataController.close();
  }
}
