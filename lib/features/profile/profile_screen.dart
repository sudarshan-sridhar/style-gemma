import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/firestore_service.dart';
import '../../core/storage/profile_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/ai_styling_service.dart';
import '../auth/auth_provider.dart';
import 'body_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _useCm = true;
  List<String> _selectedStyles = [];

  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _shoulderController = TextEditingController();
  final _heightController = TextEditingController();

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final styles = await ProfileStorage.loadStyles();
    final unit = await ProfileStorage.loadUnit();
    final measurements = await ProfileStorage.loadMeasurements();

    setState(() {
      _selectedStyles = styles;
      _useCm = unit;
      _chestController.text = measurements['chest'] ?? '';
      _waistController.text = measurements['waist'] ?? '';
      _shoulderController.text = measurements['shoulder'] ?? '';
      _heightController.text = measurements['height'] ?? '';
    });
  }

  Future<void> _toggleStyle(String style, bool selected) async {
    HapticFeedback.selectionClick();

    setState(() {
      selected ? _selectedStyles.add(style) : _selectedStyles.remove(style);
    });

    await ProfileStorage.saveStyles(_selectedStyles);
    await FirestoreService.saveProfile(stylePreferences: _selectedStyles);
  }

  Future<void> _toggleUnit(bool value) async {
    HapticFeedback.selectionClick();

    double cmToIn(double v) => v / 2.54;
    double inToCm(double v) => v * 2.54;

    void convert(TextEditingController c, double Function(double) fn) {
      if (c.text.isEmpty) return;
      final v = double.tryParse(c.text);
      if (v != null) c.text = fn(v).toStringAsFixed(1);
    }

    setState(() {
      if (value) {
        convert(_chestController, inToCm);
        convert(_waistController, inToCm);
        convert(_shoulderController, inToCm);
        convert(_heightController, inToCm);
      } else {
        convert(_chestController, cmToIn);
        convert(_waistController, cmToIn);
        convert(_shoulderController, cmToIn);
        convert(_heightController, cmToIn);
      }
      _useCm = value;
    });

    await ProfileStorage.saveUnit(value);
    await FirestoreService.saveProfile(useCm: value);
    await _saveMeasurements();
  }

  Future<void> _saveMeasurements() async {
    final measurements = {
      'chest': _chestController.text,
      'waist': _waistController.text,
      'shoulder': _shoulderController.text,
      'height': _heightController.text,
    };

    await ProfileStorage.saveMeasurements(
      chest: measurements['chest']!,
      waist: measurements['waist']!,
      shoulder: measurements['shoulder']!,
      height: measurements['height']!,
    );

    await FirestoreService.saveProfile(measurements: measurements);
  }

  Future<void> _runAiStyling() async {
    HapticFeedback.mediumImpact();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('AI is styling your wardrobe...'),
                SizedBox(height: 8),
                Text(
                  'This may take 10-30 seconds',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      print('🎨 Button clicked - starting AI styling');

      await AiStylingService.clearExistingOutfits();
      await AiStylingService.runAiStyling();

      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ AI styling complete! Check Home screen'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ AI STYLING ERROR: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _saveMeasurements();
    _chestController.dispose();
    _waistController.dispose();
    _shoulderController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: authController.signOut,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User', style: AppTextStyles.subtitle),
                  const SizedBox(height: 8),
                  _InfoTile(
                    title: 'Name',
                    value: _user?.displayName ?? 'Not set',
                  ),
                  _InfoTile(title: 'Email', value: _user?.email ?? '—'),
                ],
              ),
            ),
          ),

          _ExpandableSection(
            title: 'Style Preferences',
            child: _PreferencesSection(
              selectedStyles: _selectedStyles,
              onToggle: _toggleStyle,
            ),
          ),

          _ExpandableSection(
            title: 'Measurements',
            child: _MeasurementsSection(
              useCm: _useCm,
              onToggleUnit: _toggleUnit,
              chest: _chestController,
              waist: _waistController,
              shoulder: _shoulderController,
              height: _heightController,
            ),
          ),

          const _ExpandableSection(title: 'Body Setup', child: BodySection()),

          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.hmBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: _runAiStyling,
                    child: const Text(
                      'Re-run AI Styling',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- Expandable Section ---------------- */

class _ExpandableSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ExpandableSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Text(title, style: AppTextStyles.subtitle),
        children: [child],
      ),
    );
  }
}

/* ---------------- Sections ---------------- */

class _PreferencesSection extends StatelessWidget {
  final List<String> selectedStyles;
  final Future<void> Function(String, bool) onToggle;

  const _PreferencesSection({
    required this.selectedStyles,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const styles = [
      'Casual',
      'Business Casual',
      'Formal',
      'Party',
      'Streetwear',
      'Gym',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: styles.map((s) {
        final selected = selectedStyles.contains(s);
        return ChoiceChip(
          label: Text(s),
          selected: selected,
          selectedColor: AppColors.hmBlue,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.gray1,
          ),
          onSelected: (v) => onToggle(s, v),
        );
      }).toList(),
    );
  }
}

class _MeasurementsSection extends StatelessWidget {
  final bool useCm;
  final ValueChanged<bool> onToggleUnit;
  final TextEditingController chest;
  final TextEditingController waist;
  final TextEditingController shoulder;
  final TextEditingController height;

  const _MeasurementsSection({
    required this.useCm,
    required this.onToggleUnit,
    required this.chest,
    required this.waist,
    required this.shoulder,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Text('Units'),
            const Spacer(),
            Text(
              'IN',
              style: TextStyle(
                color: !useCm ? AppColors.hmBlue : Colors.grey,
                fontWeight: !useCm ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Switch(value: useCm, onChanged: onToggleUnit),
            const SizedBox(width: 8),
            Text(
              'CM',
              style: TextStyle(
                color: useCm ? AppColors.hmBlue : Colors.grey,
                fontWeight: useCm ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _field('Chest', chest),
        _field('Waist', waist),
        _field('Shoulder', shoulder),
        _field('Height', height),
      ],
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
        ),
      ),
    );
  }
}

/* ---------------- UI Helpers ---------------- */

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.body),
      subtitle: Text(value),
    );
  }
}
