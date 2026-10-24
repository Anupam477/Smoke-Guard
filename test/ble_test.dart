import 'package:flutter_test/flutter_test.dart';
import 'package:smokeguard/data/models/device_model.dart';
import 'package:smokeguard/services/ble/mock_ble_service.dart';
import 'package:smokeguard/services/ble/sensor_packet_parser.dart';

void main() {
  group('Phase 4 BLE & Packet Parser Unit Tests', () {
    test('SensorPacketParser encodes and decodes little-endian 9-byte packet accurately', () {
      final rawBytes = SensorPacketParser.encode(
        pm25: 45, // 45 ug/m3
        voc: 120, // 120 VOC index
        temperature: 23.5, // 23.5 C -> 235 int16
        humidity: 55.2, // 55.2 % -> 552 uint16
        battery: 85, // 85 % uint8
      );

      expect(rawBytes.length, equals(9));

      final parsed = SensorPacketParser.parse(rawBytes);

      expect(parsed.pm25, equals(45));
      expect(parsed.voc, equals(120));
      expect(parsed.temperature, closeTo(23.5, 0.1));
      expect(parsed.humidity, closeTo(55.2, 0.1));
      expect(parsed.battery, equals(85));
    });

    test('SensorPacketParser handles negative temperature properly', () {
      final rawBytes = SensorPacketParser.encode(
        pm25: 15,
        voc: 30,
        temperature: -4.5, // -4.5 C -> -45 int16
        humidity: 60.0,
        battery: 99,
      );

      final parsed = SensorPacketParser.parse(rawBytes);
      expect(parsed.temperature, closeTo(-4.5, 0.1));
    });

    test('SensorPacketParser throws error on truncated byte stream', () {
      expect(
        () => SensorPacketParser.parse([0x01, 0x02, 0x03]),
        throwsException,
      );
    });

    test('MockBleService scan and connect lifecycle', () async {
      final service = MockBleService();

      expect(service.currentStatus, equals(BleConnectionStatus.disconnected));

      final devices = await service.scanDevices().last;
      expect(devices.isNotEmpty, isTrue);

      final deviceToConnect = devices.first;
      await service.connect(deviceToConnect);

      expect(service.currentStatus, equals(BleConnectionStatus.connected));
      expect(service.connectedDevice?.bluetoothId, equals(deviceToConnect.bluetoothId));

      await service.disconnect();
      expect(service.currentStatus, equals(BleConnectionStatus.disconnected));

      service.dispose();
    });
  });
}
