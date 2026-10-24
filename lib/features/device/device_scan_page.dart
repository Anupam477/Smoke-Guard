import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/device_model.dart';
import 'device_controller.dart';

class DeviceScanPage extends ConsumerStatefulWidget {
  const DeviceScanPage({super.key});

  @override
  ConsumerState<DeviceScanPage> createState() => _DeviceScanPageState();
}

class _DeviceScanPageState extends ConsumerState<DeviceScanPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Auto-start scanning on entry
    Future.microtask(() {
      ref.read(deviceControllerProvider.notifier).startScan();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceState = ref.watch(deviceControllerProvider);
    final controller = ref.read(deviceControllerProvider.notifier);
    final isScanning = deviceState.isScanning;
    final connectedDevice = deviceState.connectedDevice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair SmokeGuard Sensor'),
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.stop_circle_outlined : Icons.refresh),
            onPressed: () {
              if (isScanning) {
                controller.stopScan();
              } else {
                controller.startScan();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scanner Header & Radar Animation
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isScanning)
                        RotationTransition(
                          turns: _pulseController,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bluetooth_searching,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isScanning
                        ? 'Searching for nearby SmokeGuard sensors...'
                        : 'Scan complete. Select your device below.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Connected Device Card (if active)
            if (connectedDevice != null &&
                deviceState.connectionStatus == BleConnectionStatus.connected) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                connectedDevice.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => controller.disconnect(),
                              child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ID: ${connectedDevice.bluetoothId}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.battery_charging_full, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  '${connectedDevice.batteryLevel}%',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/calibration'),
                            icon: const Icon(Icons.tune),
                            label: const Text('Calibrate Clean-Air Baseline'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Discovered Devices List
            Expanded(
              child: deviceState.discoveredDevices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.devices_other, size: 48, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No devices found yet.\nMake sure your SmokeGuard sensor is powered on.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: deviceState.discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final dev = deviceState.discoveredDevices[index];
                        final isConnecting =
                            deviceState.connectionStatus == BleConnectionStatus.connecting;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.watch, color: Color(0xFF0D9488)),
                            ),
                            title: Text(
                              dev.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('MAC: ${dev.bluetoothId} • RSSI: ${dev.rssi ?? -60} dBm'),
                            trailing: ElevatedButton(
                              onPressed: isConnecting ? null : () => controller.connect(dev),
                              child: isConnecting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Connect'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
