import 'package:flutter/material.dart';

class AwarenessPage extends StatefulWidget {
  const AwarenessPage({super.key});

  @override
  State<AwarenessPage> createState() => _AwarenessPageState();
}

class _AwarenessPageState extends State<AwarenessPage> {
  final List<bool> _expandedMyths = [false, false, false];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passive Smoke Awareness', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Guide Banner
            _buildHeroGuideBanner(theme),
            const SizedBox(height: 16),

            // Immediate Action Protocol
            _buildActionProtocolCard(theme),
            const SizedBox(height: 16),

            // Health Topics Carousel / Cards
            const Text(
              'Key Health Concepts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildTopicCard(
              icon: Icons.smoking_rooms,
              color: Colors.orange,
              title: 'Secondhand Smoke (SHS)',
              description:
                  'Contains over 7,000 chemicals, including 70 known carcinogens. Non-smokers exposed to SHS inhale the same dangerous fine particles (PM2.5) as smokers.',
            ),
            const SizedBox(height: 10),
            _buildTopicCard(
              icon: Icons.chair_outlined,
              color: Colors.purple,
              title: 'Thirdhand Smoke Residue',
              description:
                  'Toxic chemical particulate settles on carpets, clothes, car upholstery, and walls, remaining for months and reacting with indoor pollutants into secondary carcinogens.',
            ),
            const SizedBox(height: 10),
            _buildTopicCard(
              icon: Icons.air,
              color: Colors.blue,
              title: 'Vape Aerosols vs Smoke',
              description:
                  'While lacking tar, e-cigarette aerosols emit ultrafine nicotine particulates, heavy metals (nickel, tin, lead), and volatile flavor chemicals harmful to vulnerable lungs.',
            ),
            const SizedBox(height: 20),

            // Myth vs Fact Section
            const Text(
              'Myth vs Fact',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildMythTile(
              index: 0,
              myth: 'Opening a window clears all secondhand smoke.',
              fact:
                  'Fact: Air drafts only disperse the visible smoke. Toxic PM2.5 particles and VOCs linger indoors and re-circulate throughout the rooms.',
            ),
            _buildMythTile(
              index: 1,
              myth: 'Thirdhand smoke is harmless because there is no smell.',
              fact:
                  'Fact: Nicotine residues remain toxic long after the odor disappears, especially for infants and toddlers crawling on floors.',
            ),
            _buildMythTile(
              index: 2,
              myth: 'Air fresheners purify smoke from room air.',
              fact:
                  'Fact: Air fresheners release additional Volatile Organic Compounds (VOCs) that mask odors while making total chemical toxicity worse.',
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroGuideBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.health_and_safety_outlined, size: 40, color: Colors.white),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protecting Your Air Safety',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Understanding passive smoke exposure and taking proactive steps reduces respiratory distress and long-term health risks.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionProtocolCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber, size: 22),
                SizedBox(width: 8),
                Text(
                  'When SmokeGuard Sensor Alarms',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _protocolStep('1', 'Increase Distance: Move at least 25 feet away from tobacco or vape sources.'),
            const SizedBox(height: 8),
            _protocolStep('2', 'Ventilate or Purify: Activate HEPA air filtration or close windows facing smoking zones.'),
            const SizedBox(height: 8),
            _protocolStep('3', 'Respiratory Protection: If transit cannot be avoided, equip an N95 particulate respirator.'),
          ],
        ),
      ),
    );
  }

  Widget _protocolStep(String step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.15),
          child: Text(
            step,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, height: 1.3)),
        ),
      ],
    );
  }

  Widget _buildTopicCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMythTile({
    required int index,
    required String myth,
    required String fact,
  }) {
    final isExpanded = _expandedMyths[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.grey.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (val) {
            setState(() {
              _expandedMyths[index] = val;
            });
          },
          leading: const Icon(Icons.help_outline, color: Color(0xFF0D9488), size: 20),
          title: Text(
            myth,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
              child: Text(
                fact,
                style: const TextStyle(fontSize: 12, color: Colors.teal, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
