import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'device_controller.dart';

class CalibrationPage extends ConsumerWidget {
  const CalibrationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deviceState = ref.watch(deviceControllerProvider);
    final controller = ref.read(deviceControllerProvider.notifier);

    final isCalibrating = deviceState.isCalibrating;
    final progress = deviceState.calibrationProgress;
    final isDone = progress >= 1.0;
    final secondsRemaining = ((1.0 - progress) * 60).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Calibration'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clean Air Warning Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.teal.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.teal, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Keep the device in clean air during calibration.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Circular Countdown Progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: isCalibrating ? progress : (isDone ? 1.0 : 0.0),
                      strokeWidth: 10,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDone ? Colors.green : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDone) ...[
                        const Icon(Icons.check_circle, size: 56, color: Colors.green),
                        const SizedBox(height: 8),
                        const Text(
                          'Calibrated!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ] else if (isCalibrating) ...[
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$secondsRemaining s remaining',
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ] else ...[
                        const Icon(Icons.air, size: 48, color: Colors.teal),
                        const SizedBox(height: 8),
                        const Text(
                          '60 Seconds',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              Text(
                isDone
                    ? 'Sensor clean-air zero reference baseline successfully established.'
                    : 'The sensor needs 60 seconds in clean air to calculate its zero-point baseline for PM2.5 and VOC indices.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // Action Buttons
              if (!isCalibrating && !isDone) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.startCalibration(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Calibration (60s)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else if (isCalibrating) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => controller.cancelCalibration(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel Calibration'),
                  ),
                ),
              ] else if (isDone) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => controller.startCalibration(),
                        child: const Text('Recalibrate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
