class AppFailure implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppFailure(this.message, {this.code, this.details});

  @override
  String toString() => 'AppFailure($code): $message';
}

class BluetoothFailure extends AppFailure {
  const BluetoothFailure(super.message, {super.code, super.details});

  factory BluetoothFailure.off() => const BluetoothFailure(
        'Bluetooth is turned off. Please turn on Bluetooth to connect to your SmokeGuard device.',
        code: 'BT_OFF',
      );

  factory BluetoothFailure.permissionDenied() => const BluetoothFailure(
        'Bluetooth permission was denied. Please allow Bluetooth access in app settings.',
        code: 'BT_PERMISSION_DENIED',
      );

  factory BluetoothFailure.deviceDisconnected() => const BluetoothFailure(
        'SmokeGuard wearable sensor disconnected. Attempting auto-reconnect...',
        code: 'BT_DISCONNECTED',
      );

  factory BluetoothFailure.sensorError([String? detail]) => BluetoothFailure(
        'Sensor hardware error: ${detail ?? "Invalid data packet received"}.',
        code: 'BT_SENSOR_ERROR',
      );
}

class CalibrationFailure extends AppFailure {
  const CalibrationFailure(super.message, {super.code, super.details});

  factory CalibrationFailure.interrupted() => const CalibrationFailure(
        'Calibration was interrupted. Please ensure the sensor is in clean air and try again.',
        code: 'CALIBRATION_INTERRUPTED',
      );
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.code, super.details});
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.code, super.details});

  factory NetworkFailure.offline() => const NetworkFailure(
        'No internet connection. SmokeGuard will store data locally and sync when online.',
        code: 'OFFLINE',
      );
}

class AiAnalysisFailure extends AppFailure {
  const AiAnalysisFailure(super.message, {super.code, super.details});
}

class NotificationPermissionFailure extends AppFailure {
  const NotificationPermissionFailure()
      : super(
          'Notification permissions are required to alert you when smoke exposure is detected.',
          code: 'NOTIFICATION_PERMISSION_DENIED',
        );
}

class TtsFailure extends AppFailure {
  const TtsFailure(super.message, {super.code, super.details});
}
