import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/demo_mode_provider.dart';
import 'ble_service.dart';
import 'mock_ble_service.dart';
import 'real_ble_service.dart';

final mockBleServiceProvider = Provider<MockBleService>((ref) {
  final service = MockBleService();
  ref.onDispose(() => service.dispose());
  return service;
});

final realBleServiceProvider = Provider<RealBleService>((ref) {
  final service = RealBleService();
  ref.onDispose(() => service.dispose());
  return service;
});

final bleServiceProvider = Provider<IBleService>((ref) {
  final isDemoMode = ref.watch(demoModeProvider);

  if (isDemoMode) {
    return ref.watch(mockBleServiceProvider);
  } else {
    return ref.watch(realBleServiceProvider);
  }
});
