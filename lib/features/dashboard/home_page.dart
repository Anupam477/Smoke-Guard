import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/device_model.dart';
import '../../services/alerts/alarm_service.dart';
import '../device/device_controller.dart';
import '../exposure/exposure_controller.dart';
import '../settings/demo_mode_provider.dart';
import 'widgets/animated_hazard_banner.dart';
import 'widgets/animated_radial_gauge.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exposureState = ref.watch(exposureControllerProvider);
    final deviceState = ref.watch(deviceControllerProvider);
    final isDemoMode = ref.watch(demoModeProvider);

    final isConnected = deviceState.connectionStatus == BleConnectionStatus.connected;
    final level = exposureState.currentLevel;
    final reading = exposureState.currentReading;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 8),
            const Text('SmokeGuard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          if (isDemoMode)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger sensor refresh
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Device Connection Status Banner
              _buildDeviceBanner(context, ref, isConnected, deviceState),
              const SizedBox(height: 16),

              // 2. Critical Smoke Hazard Warning Banner (if elevated or drill active)
              if (level == AirQualityLevel.unhealthy ||
                  level == AirQualityLevel.hazardous ||
                  exposureState.isSpikeSimulationActive ||
                  ref.watch(alarmServiceProvider).isAlarming)
                AnimatedHazardBanner(exposureState: exposureState),

              // 3. Central Air Quality & Smoke Hero Card
              _buildAirQualityHeroCard(context, theme, exposureState),
              const SizedBox(height: 16),

              // 4. Personal Exposure Index (PEI) Card
              _buildPeiCard(theme, exposureState),
              const SizedBox(height: 16),

              // 5. Environmental 4-Metric Grid
              _buildTelemetryGrid(theme, reading),
              const SizedBox(height: 20),

              // 6. Fast Action Controls & Simulation
              _buildQuickActions(context, ref, isDemoMode, exposureState),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceBanner(
    BuildContext context,
    WidgetRef ref,
    bool isConnected,
    DeviceState deviceState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConnected ? Colors.green.withValues(alpha: 0.4) : Colors.amber.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
            color: isConnected ? Colors.green : Colors.amber.shade800,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isConnected
                      ? (deviceState.connectedDevice?.name ?? 'SmokeGuard Wearable')
                      : 'Sensor Disconnected',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  isConnected
                      ? 'Live Telemetry Active • Battery: ${deviceState.connectedDevice?.batteryLevel ?? 88}%'
                      : 'Tap to connect your wearable smoke badge',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isConnected ? Colors.grey.shade200 : Theme.of(context).colorScheme.primary,
              foregroundColor: isConnected ? Colors.black87 : Colors.white,
            ),
            onPressed: () {
              if (isConnected) {
                ref.read(deviceControllerProvider.notifier).disconnect();
              } else {
                context.push('/device-scan');
              }
            },
            child: Text(
              isConnected ? 'Disconnect' : 'Connect',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirQualityHeroCard(
    BuildContext context,
    ThemeData theme,
    ExposureState state,
  ) {
    final level = state.currentLevel;
    final reading = state.currentReading;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              level.color.withValues(alpha: 0.08),
              level.color.withValues(alpha: 0.02),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: level.color),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      level.label.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: level.color,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'AI: ${state.aiConfidencePercent}%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Animated Radial Gauge with Breathing Glow & Rolling Numeric Digits
            AnimatedRadialGauge(
              level: level,
              pm25: reading.pm25,
              isSpikeActive: state.isSpikeSimulationActive,
            ),
            const SizedBox(height: 20),

            // AI Source classification
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Identified: ${state.detectedSource}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeiCard(ThemeData theme, ExposureState state) {
    final pei = state.peiScore;
    Color peiColor = Colors.green;
    String peiStatus = 'Low Accumulation';
    if (pei > 60) {
      peiColor = Colors.red;
      peiStatus = 'High Daily Risk';
    } else if (pei > 30) {
      peiColor = Colors.orange;
      peiStatus = 'Moderate Exposure';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights, size: 18, color: Color(0xFF0D9488)),
                    SizedBox(width: 8),
                    Text(
                      'Personal Exposure Index (PEI)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: peiColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    peiStatus,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: peiColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pei / 100.0).clamp(0.02, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(peiColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: ${pei.toStringAsFixed(1)} / 100',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  'Daily Dose: ${state.dailyDoseAccumulated.toStringAsFixed(1)} µg/m³·h',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryGrid(ThemeData theme, dynamic reading) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _metricTile(
                icon: Icons.bubble_chart,
                iconColor: Colors.purple,
                label: 'VOC Index',
                value: '${reading.voc}',
                unit: 'pts',
                subtitle: reading.voc < 100 ? 'Clean VOC' : 'Chemical / Odor',
              ),
              const SizedBox(height: 10),
              _metricTile(
                icon: Icons.thermostat,
                iconColor: Colors.deepOrange,
                label: 'Temperature',
                value: '${reading.temperature.toStringAsFixed(1)}',
                unit: '°C',
                subtitle: 'Ambient Sensor',
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _metricTile(
                icon: Icons.water_drop,
                iconColor: Colors.blue,
                label: 'Humidity',
                value: '${reading.humidity.toStringAsFixed(0)}',
                unit: '%',
                subtitle: 'RH Ambient',
              ),
              const SizedBox(height: 10),
              _metricTile(
                icon: Icons.battery_charging_full,
                iconColor: Colors.teal,
                label: 'Badge Battery',
                value: '${reading.battery}',
                unit: '%',
                subtitle: 'BLE Wearable',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required String subtitle,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    bool isDemoMode,
    ExposureState exposureState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Safety Controls',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Calibrate'),
                onPressed: () => context.push('/calibration'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF Report'),
                onPressed: () => context.push('/reports'),
              ),
            ),
          ],
        ),
        if (isDemoMode) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: exposureState.isSpikeSimulationActive
                    ? Colors.red
                    : const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(
                exposureState.isSpikeSimulationActive
                    ? Icons.smoke_free
                    : Icons.smoking_rooms,
                size: 20,
              ),
              label: Text(
                exposureState.isSpikeSimulationActive
                  ? 'Simulating Smoke Spike (15s)...'
                  : 'Test Smoke Spike Simulation Drill',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ref.read(exposureControllerProvider.notifier).simulateSmokeSpike();
              },
            ),
          ),
        ],
      ],
    );
  }
}
