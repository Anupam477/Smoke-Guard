import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_profile.dart';
import '../../core/theme/locale_provider.dart';
import 'profile_controller.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedAgeGroup = '26-40';
  SensitivityLevel _selectedSensitivity = SensitivityLevel.medium;
  final Set<String> _selectedConditions = {};
  String _selectedLanguage = 'en';

  final List<String> _ageGroups = const [
    'Under 18',
    '18-25',
    '26-40',
    '41-60',
    '60+',
  ];

  final List<String> _availableConditions = const [
    'Asthma',
    'Respiratory Allergies',
    'Heart Condition',
    'Pregnancy',
    'None',
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).profile;
    if (profile != null) {
      _nameController.text = profile.displayName;
      _phoneController.text = profile.phone ?? '';
      _selectedAgeGroup = profile.ageGroup;
      _selectedSensitivity = profile.sensitivityLevel;
      _selectedConditions.addAll(profile.healthPreferences);
      _selectedLanguage = profile.preferredLanguage;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          displayName: _nameController.text.trim().isEmpty
              ? 'SmokeGuard User'
              : _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          ageGroup: _selectedAgeGroup,
          sensitivityLevel: _selectedSensitivity,
          healthPreferences: _selectedConditions.toList(),
          preferredLanguage: _selectedLanguage,
        );

    // Update global app locale
    await ref.read(localeProvider.notifier).setLocale(_selectedLanguage);

    if (success && mounted) {
      context.go('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileControllerProvider);
    final isLoading = profileState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Health Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalize Your Exposure Index',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'SmokeGuard customizes the Personal Exposure Index (PEI) based on your physiological sensitivity.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Display Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name / Display Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Phone (Optional)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Age Group
              Text(
                'Age Group',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _ageGroups.map((group) {
                  final isSelected = _selectedAgeGroup == group;
                  return ChoiceChip(
                    label: Text(group),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedAgeGroup = group;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Sensitivity Level
              Text(
                'Smoke Sensitivity Level',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Adjusts PEI calculation factor (Low x0.8, Medium x1.0, High x1.3).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<SensitivityLevel>(
                segments: const [
                  ButtonSegment(
                    value: SensitivityLevel.low,
                    label: Text('Low (0.8x)'),
                  ),
                  ButtonSegment(
                    value: SensitivityLevel.medium,
                    label: Text('Medium (1.0x)'),
                  ),
                  ButtonSegment(
                    value: SensitivityLevel.high,
                    label: Text('High (1.3x)'),
                  ),
                ],
                selected: {_selectedSensitivity},
                onSelectionChanged: (newVal) {
                  setState(() {
                    _selectedSensitivity = newVal.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Health Conditions
              Text(
                'Respiratory or Health Considerations',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableConditions.map((condition) {
                  final isSelected = _selectedConditions.contains(condition);
                  return FilterChip(
                    label: Text(condition),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (condition == 'None') {
                          _selectedConditions.clear();
                          if (selected) _selectedConditions.add('None');
                        } else {
                          _selectedConditions.remove('None');
                          if (selected) {
                            _selectedConditions.add(condition);
                          } else {
                            _selectedConditions.remove(condition);
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Preferred Language
              Text(
                'Preferred App Language',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'en', label: Text('English')),
                  ButtonSegment(value: 'hi', label: Text('हिंदी (Hindi)')),
                ],
                selected: {_selectedLanguage},
                onSelectionChanged: (val) {
                  setState(() {
                    _selectedLanguage = val.first;
                  });
                },
              ),
              const SizedBox(height: 36),

              // Save & Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
