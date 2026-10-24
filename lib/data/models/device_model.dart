enum BleConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting;

  String get displayName {
    switch (this) {
      case BleConnectionStatus.disconnected:
        return 'Disconnected';
      case BleConnectionStatus.connecting:
        return 'Connecting...';
      case BleConnectionStatus.connected:
        return 'Connected';
      case BleConnectionStatus.reconnecting:
        return 'Reconnecting...';
    }
  }
}

class SmokeGuardDevice {
  final String id;
  final String name;
  final String bluetoothId; // MAC address or UUID
  final int batteryLevel; // 0-100%
  final BleConnectionStatus connectionStatus;
  final bool isCalibrated;
  final DateTime? lastConnectedAt;
  final int? rssi; // Signal strength

  const SmokeGuardDevice({
    required this.id,
    required this.name,
    required this.bluetoothId,
    this.batteryLevel = 100,
    this.connectionStatus = BleConnectionStatus.disconnected,
    this.isCalibrated = false,
    this.lastConnectedAt,
    this.rssi,
  });

  factory SmokeGuardDevice.mock() {
    return SmokeGuardDevice(
      id: 'dev_mock_001',
      name: 'SmokeGuard-V1 #4829',
      bluetoothId: 'SG:48:29:AA:BB:CC',
      batteryLevel: 88,
      connectionStatus: BleConnectionStatus.connected,
      isCalibrated: true,
      lastConnectedAt: DateTime.now(),
      rssi: -58,
    );
  }

  SmokeGuardDevice copyWith({
    String? id,
    String? name,
    String? bluetoothId,
    int? batteryLevel,
    BleConnectionStatus? connectionStatus,
    bool? isCalibrated,
    DateTime? lastConnectedAt,
    int? rssi,
  }) {
    return SmokeGuardDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      bluetoothId: bluetoothId ?? this.bluetoothId,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      rssi: rssi ?? this.rssi,
    );
  }
}
