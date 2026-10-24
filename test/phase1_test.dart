import 'package:flutter_test/flutter_test.dart';
import 'package:smokeguard/core/constants/app_constants.dart';
import 'package:smokeguard/core/config/env_config.dart';
import 'package:smokeguard/core/errors/failures.dart';

void main() {
  group('Phase 1 Core Unit Tests', () {
    test('AppConstants values are correct', () {
      expect(AppConstants.appName, equals('SmokeGuard'));
      expect(AppConstants.bleServiceUuid, equals('00005247-0000-1000-8000-00805f9b34fb'));
      expect(AppConstants.calibrationDurationSeconds, equals(60));
    });

    test('EnvConfig defaults are configured', () {
      expect(EnvConfig.defaultDemoMode, isTrue);
      expect(EnvConfig.enablePhoneOtp, isTrue);
      expect(EnvConfig.enableLocationTracking, isTrue);
    });

    test('AppFailures instantiate with correct message and code', () {
      final btOff = BluetoothFailure.off();
      expect(btOff.code, equals('BT_OFF'));

      final btPermission = BluetoothFailure.permissionDenied();
      expect(btPermission.code, equals('BT_PERMISSION_DENIED'));

      final netOffline = NetworkFailure.offline();
      expect(netOffline.code, equals('OFFLINE'));

      final calibrationError = CalibrationFailure.interrupted();
      expect(calibrationError.code, equals('CALIBRATION_INTERRUPTED'));
    });
  });
}
