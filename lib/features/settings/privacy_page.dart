import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy & Data Security')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Your Data Privacy in SmokeGuard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'SmokeGuard collects environmental sensor telemetry (PM2.5, VOC, Temperature, Humidity) to analyze smoke exposure. Data is stored locally offline-first and synced to Supabase securely under strict Row Level Security (RLS). You can manage or delete your data at any time.',
            ),
          ],
        ),
      ),
    );
  }
}
