import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/user_profile.dart';
import '../profile/profile_controller.dart';
import 'exposure_controller.dart';

class ExposurePage extends ConsumerWidget {
  const ExposurePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exposureState = ref.watch(exposureControllerProvider);
    final profile = ref.watch(profileControllerProvider).profile;

    final pei = exposureState.peiScore;
    final incidents = exposureState.incidents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exposure History & PEI', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Incidents',
            onPressed: () {
              ref.read(exposureControllerProvider.notifier).clearIncidents();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exposure incidents cleared')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. PEI Health Risk Overview Card
            _buildPeiOverviewCard(theme, pei, profile),
            const SizedBox(height: 16),

            // 2. Exposure Time Distribution (Pie/Bar breakdown)
            _buildDurationBreakdownCard(theme),
            const SizedBox(height: 16),

            // 3. User Health Sensitivity Alert (if applicable)
            if (profile != null && (profile.hasAsthma || profile.hasCopd || profile.isPregnant))
              _buildSensitivityAlertCard(theme, profile),

            // 4. Chronological Incident Log Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detected Smoke Incidents',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${incidents.length} recorded today',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5. Incidents List or Empty state
            if (incidents.isEmpty)
              _buildEmptyIncidentsState(theme)
            else
              ...incidents.map((inc) => _buildIncidentCard(theme, inc)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPeiOverviewCard(ThemeData theme, double pei, UserProfile? profile) {
    Color statusColor = Colors.green;
    String statusTitle = 'Minimal Smoke Inhalation';
    String statusDesc = 'Air exposure is within normal physiological tolerance.';

    if (pei > 60) {
      statusColor = Colors.red;
      statusTitle = 'Elevated Risk Level';
      statusDesc = 'Significant smoke particulate accumulated today.';
    } else if (pei > 25) {
      statusColor = Colors.orange;
      statusTitle = 'Moderate Inhalation';
      statusDesc = 'Mild smoke episodes detected. Rest in clean air recommended.';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${pei.round()}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusDesc,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Inhaled PM2.5', '16.4 µg', Icons.air),
                _miniStat('Peak Sensor', '78 µg/m³', Icons.trending_up),
                _miniStat('Daily Budget', '${(100 - pei).round()}% Left', Icons.pie_chart_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDurationBreakdownCard(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Environment Time Distribution',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  Expanded(flex: 88, child: Container(height: 14, color: Colors.green)),
                  Expanded(flex: 9, child: Container(height: 14, color: Colors.amber)),
                  Expanded(flex: 3, child: Container(height: 14, color: Colors.red)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _legendItem('Clean Air', '88% (7h 12m)', Colors.green),
                _legendItem('Moderate', '9% (45m)', Colors.amber),
                _legendItem('Smoky', '3% (15m)', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildSensitivityAlertCard(ThemeData theme, UserProfile profile) {
    final List<String> conditions = [];
    if (profile.hasAsthma) conditions.add('Asthma');
    if (profile.hasCopd) conditions.add('COPD');
    if (profile.isPregnant) conditions.add('Pregnancy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.health_and_safety, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Profile Health Alert (${conditions.join(', ')}): SmokeGuard has scaled your Personal Exposure Index with high sensitivity threshold.',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyIncidentsState(ThemeData theme) {
    return Card(
      elevation: 0,
      color: Colors.grey.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
        child: Column(
          children: [
            Icon(Icons.verified_outlined, size: 48, color: Colors.green),
            SizedBox(height: 12),
            Text(
              'No Severe Smoke Incidents Today',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 4),
            Text(
              'Your wearable sensor has recorded safe ambient air levels.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(ThemeData theme, ExposureIncident incident) {
    final timeStr = DateFormat('h:mm a').format(incident.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: incident.severity.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_amber_rounded, color: incident.severity.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        incident.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Peak: ${incident.peakPm25} µg/m³',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: incident.severity.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• Duration: ${incident.durationMinutes} min',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        incident.locationTag,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
