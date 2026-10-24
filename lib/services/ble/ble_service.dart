import '../../data/models/device_model.dart';
import 'sensor_packet_parser.dart';

abstract class IBleService {
  Stream<List<SmokeGuardDevice>> scanDevices();
  Future<void> stopScan();
  Future<void> connect(SmokeGuardDevice device);
  Future<void> disconnect();
  Stream<ParsedSensorData> subscribeToSensorData();
  Stream<BleConnectionStatus> get connectionStatusStream;
  BleConnectionStatus get currentStatus;
  SmokeGuardDevice? get connectedDevice;
  Future<int> getBatteryLevel();
  Stream<double> calibrateSensor(); // 60s calibration baseline progress (0.0 to 1.0)
  bool get isCalibrated;
}
