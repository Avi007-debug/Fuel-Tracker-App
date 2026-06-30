import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/models/vehicle_profile.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';

/// Onboarding flow — shown on first launch.
/// Collects vehicle name, model, tank capacity, reserve, service interval.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Form fields
  final _nameController = TextEditingController(text: 'Activa');
  final _modelController = TextEditingController(text: 'Honda Activa 6G');
  final _registrationController = TextEditingController();
  final _tankCapacityController = TextEditingController(text: '5.3');
  final _reserveController = TextEditingController(text: '0.8');
  final _serviceIntervalController = TextEditingController(text: '3000');
  final _odometerController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _registrationController.dispose();
    _tankCapacityController.dispose();
    _reserveController.dispose();
    _serviceIntervalController.dispose();
    _odometerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profile = VehicleProfile(
        id: 'default',
        name: _nameController.text.trim(),
        model: _modelController.text.trim(),
        registrationNo: _registrationController.text.trim().isNotEmpty
            ? _registrationController.text.trim()
            : null,
        tankCapacityL: double.parse(_tankCapacityController.text.trim()),
        reserveL: double.parse(_reserveController.text.trim()),
        serviceIntervalKm: double.parse(_serviceIntervalController.text.trim()),
        initialOdometer: _odometerController.text.trim().isNotEmpty
            ? double.parse(_odometerController.text.trim())
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(vehicleServiceProvider).saveProfile(profile);
      ref.invalidate(vehicleProfileProvider);
      ref.invalidate(isOnboardedProvider);

      if (mounted) {
        // Navigator will be handled by app.dart watching isOnboardedProvider
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: AppTheme.accentGreen.withAlpha(20),
              color: AppTheme.accentGreen,
              minHeight: 4,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildVehiclePage(),
                    _buildFuelPage(),
                    _buildConfirmPage(),
                  ],
                ),
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentPage > 0 ? 1 : 0,
                    child: FilledButton.icon(
                      onPressed: _isLoading
                          ? null
                          : (_currentPage == 2 ? _saveProfile : _nextPage),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(_currentPage == 2
                              ? Icons.check
                              : Icons.arrow_forward),
                      label: Text(
                        _currentPage == 2
                            ? 'Get Started'
                            : _currentPage == 0
                                ? 'Next: Fuel Details'
                                : 'Review',
                      ),
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

  Widget _buildVehiclePage() {
    return _OnboardingPage(
      icon: Icons.two_wheeler,
      title: 'Your Vehicle',
      subtitle: 'Tell us about your ride',
      color: AppTheme.accentGreen,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Vehicle Name',
            prefixIcon: Icon(Icons.label_outline),
            hintText: 'e.g. Activa',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _modelController,
          decoration: const InputDecoration(
            labelText: 'Model',
            prefixIcon: Icon(Icons.motorcycle),
            hintText: 'e.g. Honda Activa 6G',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _registrationController,
          decoration: const InputDecoration(
            labelText: 'Registration Number (optional)',
            prefixIcon: Icon(Icons.pin_outlined),
            hintText: 'e.g. KA-01-AB-1234',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _odometerController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Current Odometer Reading (km, optional)',
            prefixIcon: Icon(Icons.speed_outlined),
            hintText: 'e.g. 15000',
          ),
        ),
      ],
    );
  }

  Widget _buildFuelPage() {
    return _OnboardingPage(
      icon: Icons.local_gas_station,
      title: 'Fuel Tank',
      subtitle: 'Your scooter\'s fuel specs',
      color: AppTheme.accentOrange,
      children: [
        TextFormField(
          controller: _tankCapacityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Tank Capacity (Litres)',
            prefixIcon: Icon(Icons.water_drop_outlined),
            hintText: 'e.g. 5.3',
            suffixText: 'L',
          ),
          validator: (v) {
            final val = double.tryParse(v?.trim() ?? '');
            if (val == null || val <= 0) return 'Enter valid capacity';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _reserveController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Reserve (Litres)',
            prefixIcon: Icon(Icons.warning_amber_outlined),
            hintText: 'e.g. 0.8',
            suffixText: 'L',
            helperText: 'Fuel remaining when reserve indicator lights up',
          ),
          validator: (v) {
            final val = double.tryParse(v?.trim() ?? '');
            if (val == null || val < 0) return 'Enter valid reserve';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _serviceIntervalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Service Interval',
            prefixIcon: Icon(Icons.build_outlined),
            hintText: 'e.g. 3000',
            suffixText: 'km',
            helperText: 'Recommended service interval for your vehicle',
          ),
          validator: (v) {
            final val = double.tryParse(v?.trim() ?? '');
            if (val == null || val <= 0) return 'Enter valid interval';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPage() {
    return _OnboardingPage(
      icon: Icons.check_circle_outline,
      title: 'Ready to Roll',
      subtitle: 'Confirm your setup',
      color: AppTheme.accentBlue,
      children: [
        _ConfirmCard(
          title: 'Vehicle',
          items: [
            ('Name', _nameController.text),
            ('Model', _modelController.text),
            ('Registration', _registrationController.text.isNotEmpty
                ? _registrationController.text
                : 'Not provided'),
          ],
        ),
        const SizedBox(height: 16),
        _ConfirmCard(
          title: 'Fuel',
          items: [
            ('Tank Capacity', '${_tankCapacityController.text} L'),
            ('Reserve', '${_reserveController.text} L'),
            ('Service Interval', '${_serviceIntervalController.text} km'),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withAlpha(15),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.accentGreen.withAlpha(40)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.accentGreen, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You can change these anytime in Settings.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<Widget> children;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Form fields
          ...children,
        ],
      ),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  final String title;
  final List<(String, String)> items;

  const _ConfirmCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.$1, style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      item.$2,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
