import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_provider.dart';
import '../../core/theme/locale_provider.dart';
import '../auth/auth_controller.dart';
import 'demo_mode_provider.dart';
import 'settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield, color: Color(0xFF0D9488)),
            SizedBox(width: 8),
            Text('About SmokeGuard'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SmokeGuard v1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'SmokeGuard is a wearable environmental monitoring and smoke awareness mobile application. It utilizes real-time PM2.5, VOC gas, temperature, and humidity heuristics to detect probable secondhand smoke exposure.',
              ),
              SizedBox(height: 12),
              Text(
                'IMPORTANT DISCLAIMER:\nSmokeGuard is designed for environmental monitoring and health awareness only. It does NOT provide clinical or medical diagnosis. AI classifications are confidence estimates.',
                style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);
    final isDemoMode = ref.watch(demoModeProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final settings = settingsState.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Section: Appearance & Language
          _buildSectionHeader(context, 'Appearance & Language'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme Mode'),
            subtitle: Text(themeMode.name.toUpperCase()),
            trailing: PopupMenuButton<ThemeMode>(
              initialValue: themeMode,
              onSelected: (mode) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: ThemeMode.system, child: Text('System Default')),
                PopupMenuItem(value: ThemeMode.light, child: Text('Light Mode')),
                PopupMenuItem(value: ThemeMode.dark, child: Text('Dark Mode')),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('App Language'),
            subtitle: Text(currentLocale.languageCode == 'hi' ? 'हिंदी (Hindi)' : 'English'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('EN')),
                ButtonSegment(value: 'hi', label: Text('HI')),
              ],
              selected: {currentLocale.languageCode},
              onSelectionChanged: (val) {
                ref.read(localeProvider.notifier).setLocale(val.first);
              },
            ),
          ),

          const Divider(),

          // Section: Alert Channels
          _buildSectionHeader(context, 'Alert Channels'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive immediate alerts on smoke detection'),
            value: settings.notificationsEnabled,
            onChanged: (val) {
              ref.read(settingsControllerProvider.notifier).toggleNotifications(val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.record_voice_over_outlined),
            title: const Text('Voice TTS Alerts'),
            subtitle: const Text('Spoken warning when smoke is detected'),
            value: settings.voiceAlertsEnabled,
            onChanged: (val) {
              ref.read(settingsControllerProvider.notifier).toggleVoiceAlerts(val);
            },
          ),
          if (settings.voiceAlertsEnabled) ...[
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              title: const Text('Voice Language'),
              subtitle: Text(settings.voiceLanguage == 'hi' ? 'Hindi (हिंदी)' : 'English'),
              trailing: PopupMenuButton<String>(
                initialValue: settings.voiceLanguage,
                onSelected: (lang) {
                  ref.read(settingsControllerProvider.notifier).setVoiceLanguage(lang);
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'en', child: Text('English Voice')),
                  PopupMenuItem(value: 'hi', child: Text('Hindi Voice (हिंदी)')),
                ],
              ),
            ),
          ],
          SwitchListTile(
            secondary: const Icon(Icons.watch_outlined),
            title: const Text('Smartwatch Vibration & Alerts'),
            subtitle: const Text('Haptic pulses on companion smartwatch'),
            value: settings.smartwatchAlertsEnabled,
            onChanged: (val) {
              ref.read(settingsControllerProvider.notifier).toggleSmartwatch(val);
            },
          ),

          const Divider(),

          // Section: Simulation & Data Sync
          _buildSectionHeader(context, 'Data & Simulation'),
          SwitchListTile(
            secondary: const Icon(Icons.bolt, color: Colors.amber),
            title: const Text('Demo Mode'),
            subtitle: const Text('Run without physical BLE hardware'),
            value: isDemoMode,
            onChanged: (val) {
              ref.read(demoModeProvider.notifier).toggleDemoMode(val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.cloud_sync_outlined),
            title: const Text('Cloud Sync (Supabase)'),
            subtitle: const Text('Sync telemetry & exposure history securely'),
            value: settings.cloudSyncEnabled,
            onChanged: (val) {
              ref.read(settingsControllerProvider.notifier).toggleCloudSync(val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.location_on_outlined),
            title: const Text('Tag Exposure Locations'),
            subtitle: const Text('Coarse location only for high exposure hotspots'),
            value: settings.locationEnabled,
            onChanged: (val) {
              ref.read(settingsControllerProvider.notifier).toggleLocation(val);
            },
          ),

          const Divider(),

          // Section: Legal & Information
          _buildSectionHeader(context, 'Information & Support'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy & Data Security'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Export Health & Exposure Reports'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/reports'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About SmokeGuard'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
