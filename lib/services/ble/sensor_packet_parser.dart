import 'dart:typed_data';
import '../../core/errors/failures.dart';

class ParsedSensorData {
  final int pm25; // ug/m3
  final int voc; // index
  final double temperature; // Celsius
  final double humidity; // %
  final int battery; // % (0-100)

  const ParsedSensorData({
    required this.pm25,
    required this.voc,
    required this.temperature,
    required this.humidity,
    required this.battery,
  });

  @override
  String toString() {
    return 'ParsedSensorData(PM2.5: $pm25 ug/m3, VOC: $voc, Temp: ${temperature.toStringAsFixed(1)}°C, Hum: ${humidity.toStringAsFixed(1)}%, Batt: $battery%)';
  }
}

/// ALL byte parsing for SmokeGuard lives in this single class.
/// Packet layout (9 bytes, little-endian):
/// [0..1] uint16 pm25 (ug/m3)
/// [2..3] uint16 voc (index)
/// [4..5] int16  temperature (x0.1 C, signed)
/// [6..7] uint16 humidity (x0.1 %)
/// [8]    uint8  battery (0-100 %)
class SensorPacketParser {
  SensorPacketParser._();

  static const int expectedPacketLength = 9;

  /// Parse binary payload received from SmokeGuard BLE characteristic
  static ParsedSensorData parse(List<int> rawBytes) {
    if (rawBytes.length < expectedPacketLength) {
      throw BluetoothFailure.sensorError(
        'Invalid packet length: expected $expectedPacketLength bytes, received ${rawBytes.length}',
      );
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(rawBytes));

    // Little-endian reads
    final int pm25 = byteData.getUint16(0, Endian.little);
    final int voc = byteData.getUint16(2, Endian.little);
    final int tempRaw = byteData.getInt16(4, Endian.little);
    final int humRaw = byteData.getUint16(6, Endian.little);
    final int battery = byteData.getUint8(8);

    return ParsedSensorData(
      pm25: pm25,
      voc: voc,
      temperature: tempRaw / 10.0,
      humidity: humRaw / 10.0,
      battery: battery.clamp(0, 100),
    );
  }

  /// Encode helper for Mock/Test packets
  static Uint8List encode({
    required int pm25,
    required int voc,
    required double temperature,
    required double humidity,
    required int battery,
  }) {
    final byteData = ByteData(expectedPacketLength);

    byteData.setUint16(0, pm25.clamp(0, 65535), Endian.little);
    byteData.setUint16(2, voc.clamp(0, 65535), Endian.little);

    final int rawTemp = (temperature * 10).round().clamp(-32768, 32767);
    byteData.setInt16(4, rawTemp, Endian.little);

    final int rawHum = (humidity * 10).round().clamp(0, 65535);
    byteData.setUint16(6, rawHum, Endian.little);

    byteData.setUint8(8, battery.clamp(0, 100));

    return byteData.buffer.asUint8List();
  }
}
