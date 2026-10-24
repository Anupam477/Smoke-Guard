import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/alerts/alarm_service.dart';
import '../../exposure/exposure_controller.dart';

class AnimatedHazardBanner extends ConsumerStatefulWidget {
  final ExposureState exposureState;

  const AnimatedHazardBanner({
    super.key,
    required this.exposureState,
  });

  @override
  ConsumerState<AnimatedHazardBanner> createState() =>
      _AnimatedHazardBannerState();
}

class _AnimatedHazardBannerState extends ConsumerState<AnimatedHazardBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _strobeController;
  late Animation<double> _strobeAnimation;

  @override
  void initState() {
    super.initState();
    _strobeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    _strobeAnimation = Tween<double>(begin: 0.12, end: 0.28).animate(
      CurvedAnimation(parent: _strobeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _strobeController.dispose();
    super.dispose();
  }

  void _showActionGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _EmergencyActionModal(
        source: widget.exposureState.detectedSource,
        pm25: widget.exposureState.currentReading.pm25,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alarmState = ref.watch(alarmServiceProvider);
    final isMuted = alarmState.isMuted;
    final isSpike = widget.exposureState.isSpikeSimulationActive;
    final source = widget.exposureState.detectedSource;

    return AnimatedBuilder(
      animation: _strobeAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: _strobeAnimation.value),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.8),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: _strobeAnimation.value * 0.7),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated Flashing Siren Badge
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isSpike ? '🚨 SMOKE DRILL IN PROGRESS' : '🚨 CRITICAL SMOKE HAZARD',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$source detected! Dangerous particulate spike.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mute / Unmute Siren Button
                  IconButton(
                    icon: Icon(
                      isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: isMuted ? Colors.grey.shade700 : Colors.red,
                      size: 22,
                    ),
                    tooltip: isMuted ? 'Alarm Muted' : 'Mute Siren Alarm',
                    onPressed: () {
                      if (isMuted) {
                        ref.read(alarmServiceProvider.notifier).triggerAlarm(
                              title: 'Emergency Alarm',
                              message: 'Active hazard alert',
                            );
                      } else {
                        ref.read(alarmServiceProvider.notifier).muteAlarm();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      foregroundColor: Colors.red.shade900,
                    ),
                    icon: const Icon(Icons.medical_services_outlined, size: 16),
                    label: const Text(
                      'Emergency Steps',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showActionGuide(context),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      ref.read(alarmServiceProvider.notifier).dismissAlarm();
                    },
                    child: const Text(
                      'Acknowledge',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmergencyActionModal extends StatelessWidget {
  final String source;
  final int pm25;

  const _EmergencyActionModal({
    required this.source,
    required this.pm25,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.health_and_safety_rounded, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Immediate Safety Protocol',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'PM2.5 Level: $pm25 µg/m³ ($source)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCheckItem(
            icon: Icons.directions_walk_rounded,
            title: '1. Relocate Immediately',
            description: 'Step at least 10-15 meters upwind from the smoke source.',
          ),
          const SizedBox(height: 12),
          _buildCheckItem(
            icon: Icons.masks_rounded,
            title: '2. Respiratory Protection',
            description: 'Wear an N95/FFP2 respirator mask or cover mouth/nose with clean cloth.',
          ),
          const SizedBox(height: 12),
          _buildCheckItem(
            icon: Icons.air_rounded,
            title: '3. Indoor Ventilation Control',
            description: 'Shut windows, turn on HEPA air purification, or set AC to internal recirculation.',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('I am Safe Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF00796B), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
