import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/health_provider.dart';
import '../models/health_profile_model.dart';

class HealthProfileScreen extends ConsumerStatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  ConsumerState<HealthProfileScreen> createState() =>
      _HealthProfileScreenState();
}

class _HealthProfileScreenState extends ConsumerState<HealthProfileScreen> {
  static const primaryColor = Color(0xFFEC6F2D);
  bool _isSaving = false;

  // Controllers
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _sugarController = TextEditingController();
  final _saltController = TextEditingController();

  // Form state
  String _gender = '';
  String _goal = 'eat_healthy';
  String _activityLevel = 'moderate';
  String _activityFrequency = '2_3';
  String _activityIntensity = 'moderate';
  String _activityDuration = '30_60';
  List<String> _activityTypes = [];
  String _lifestyle = 'desk';
  DateTime? _dateOfBirth;
  bool _isDiabetic = false;
  bool _hasHypertension = false;
  bool _isCeliac = false;
  bool _isLactoseIntolerant = false;
  bool _isVegan = false;
  bool _isVegetarian = false;
  bool _isFlexitarian = false;
  String _diabetesType = '';
  String _lactoseLevel = '';

  bool _initialized = false;

  void _initFromProfile(HealthProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _weightController.text = profile.weight?.toString() ?? '';
    _heightController.text = profile.height?.toString() ?? '';
    _allergiesController.text = profile.allergies;
    _gender = profile.gender ?? '';
    _goal = profile.goal;
    _activityLevel = profile.activityLevel;
    _activityFrequency = profile.activityFrequency.isNotEmpty ? profile.activityFrequency : '2_3';
    _activityIntensity = profile.activityIntensity.isNotEmpty ? profile.activityIntensity : 'moderate';
    _activityDuration = profile.activityDuration.isNotEmpty ? profile.activityDuration : '30_60';
    _activityTypes = List.from(profile.activityTypes);
    _lifestyle = profile.lifestyle.isNotEmpty ? profile.lifestyle : 'desk';
    _dateOfBirth = profile.dateOfBirth;
    _isDiabetic = profile.isDiabetic;
    _hasHypertension = profile.hasHypertension;
    _isCeliac = profile.isCeliac;
    _isLactoseIntolerant = profile.isLactoseIntolerant;
    _isVegan = profile.isVegan;
    _isVegetarian = profile.isVegetarian;
    _isFlexitarian = profile.isFlexitarian;
    _diabetesType = profile.diabetesType;
    _lactoseLevel = profile.lactoseIntoleranceLevel;
    _caloriesController.text = profile.dailyCalories?.toString() ?? '';
    _proteinController.text = profile.dailyProtein?.toString() ?? '';
    _carbsController.text = profile.dailyCarbs?.toString() ?? '';
    _fatController.text = profile.dailyFat?.toString() ?? '';
    _sugarController.text = profile.dailySugarLimit?.toString() ?? '';
    _saltController.text = profile.dailySaltLimit?.toString() ?? '';
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _allergiesController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _sugarController.dispose();
    _saltController.dispose();
    super.dispose();
  }

  Future<void> _save(HealthProfile current) async {
    setState(() => _isSaving = true);
    try {
      // Construct directly — do NOT use copyWith for nullable overrides
      // so that clearing a field sends null to backend (reverts to auto)
      final updated = HealthProfile(
        gender: _gender,
        dateOfBirth: _dateOfBirth,
        age: current.age,
        weight: double.tryParse(_weightController.text),
        height: double.tryParse(_heightController.text),
        goal: _goal,
        activityLevel: _activityLevel,
        activityFrequency: _activityFrequency,
        activityIntensity: _activityIntensity,
        activityDuration: _activityDuration,
        activityTypes: _activityTypes,
        lifestyle: _lifestyle,
        isDiabetic: _isDiabetic,
        hasHypertension: _hasHypertension,
        isCeliac: _isCeliac,
        isLactoseIntolerant: _isLactoseIntolerant,
        isVegan: _isVegan,
        isVegetarian: _isVegetarian,
        isFlexitarian: _isFlexitarian,
        diabetesType: _diabetesType,
        lactoseIntoleranceLevel: _lactoseLevel,
        allergies: _allergiesController.text.trim(),
        avatar: current.avatar,
        // null = cleared = backend reverts to auto-calculation
        dailyCalories: double.tryParse(_caloriesController.text),
        dailyProtein: double.tryParse(_proteinController.text),
        dailyCarbs: double.tryParse(_carbsController.text),
        dailyFat: double.tryParse(_fatController.text),
        dailySugarLimit: double.tryParse(_sugarController.text),
        dailySaltLimit: double.tryParse(_saltController.text),
        bmi: current.bmi,
        dailyCalorieTarget: current.dailyCalorieTarget,
        proteinTarget: current.proteinTarget,
        carbsTarget: current.carbsTarget,
        fatTarget: current.fatTarget,
        sugarLimitTarget: current.sugarLimitTarget,
        saltLimitTarget: current.saltLimitTarget,
      );
      await ref.read(healthProfileProvider.notifier).updateProfile(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(healthProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: profileState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: primaryColor)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found'));
          }
          _initFromProfile(profile);

          return Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                    24, MediaQuery.of(context).padding.top + 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => context.canPop()
                            ? context.pop()
                            : context.go('/home'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_left,
                              color: primaryColor, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Health Profile',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                    ]),
                    // BMI badge
                    if (profile.bmi != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'BMI ${profile.bmi}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryColor),
                        ),
                      ),
                  ],
                ),
              ),

              // Stats cards
              if (profile.bmi != null || profile.dailyCalorieTarget != null)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      if (profile.bmi != null)
                        Expanded(
                          child: _StatCard(
                            label: 'BMI',
                            value: profile.bmi!.toString(),
                            sub: profile.bmiCategory,
                            color: primaryColor,
                          ),
                        ),
                      if (profile.bmi != null &&
                          profile.dailyCalorieTarget != null)
                        const SizedBox(width: 12),
                      if (profile.dailyCalorieTarget != null)
                        Expanded(
                          child: _StatCard(
                            label: 'Daily Target',
                            value:
                                '${profile.dailyCalorieTarget!.toStringAsFixed(0)}',
                            sub: 'kcal/day',
                            color: const Color(0xFF27AE60),
                          ),
                        ),
                    ],
                  ),
                ),

              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.opaque,
                  child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      _SectionCard(
                        title: 'Basic Information',
                        icon: Icons.person_outline,
                        children: [
                          // Gender
                          _buildLabel('Gender'),
                          const SizedBox(height: 8),
                          _SegmentedRow(
                            options: const ['male', 'female'],
                            labels: const ['Male', 'Female'],
                            selected: _gender,
                            onSelect: (v) => setState(() => _gender = v),
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 16),
                          // Date of birth
                          _buildLabel('Date of Birth'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickDateOfBirth,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFFE0E0E0)),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(children: [
                                Icon(Icons.calendar_today_outlined,
                                    color: Colors.grey, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  _dateOfBirth != null
                                      ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                                      : 'Select date of birth',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: _dateOfBirth != null
                                          ? const Color(0xFF1A1A1A)
                                          : Colors.grey),
                                ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Weight & Height
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Weight (kg)'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                      controller: _weightController,
                                      hint: '70',
                                      keyboardType: TextInputType.number),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Height (cm)'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                      controller: _heightController,
                                      hint: '175',
                                      keyboardType: TextInputType.number),
                                ],
                              ),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Goal
                      _SectionCard(
                        title: 'Health Goal',
                        icon: Icons.flag_outlined,
                        children: [
                          _GoalGrid(
                            selected: _goal,
                            onSelect: (v) => setState(() => _goal = v),
                            primaryColor: primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Activity
                      _SectionCard(
                        title: 'Physical Activity',
                        icon: Icons.directions_run_outlined,
                        children: [
                          _ActivityScoreWidget(
                            frequency: _activityFrequency,
                            intensity: _activityIntensity,
                            duration: _activityDuration,
                            types: _activityTypes,
                            lifestyle: _lifestyle,
                            primaryColor: primaryColor,
                            onFrequencyChange: (v) => setState(() => _activityFrequency = v),
                            onIntensityChange: (v) => setState(() => _activityIntensity = v),
                            onDurationChange: (v) => setState(() => _activityDuration = v),
                            onTypesChange: (v) => setState(() => _activityTypes = v),
                            onLifestyleChange: (v) => setState(() => _lifestyle = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Medical Conditions
                      _SectionCard(
                        title: 'Medical Conditions',
                        icon: Icons.medical_services_outlined,
                        children: [
                          _ToggleRow(
                              label: 'Diabetic',
                              value: _isDiabetic,
                              onChanged: (v) => setState(() {
                                _isDiabetic = v;
                                if (!v) _diabetesType = '';
                              }),
                              primaryColor: primaryColor),
                          if (_isDiabetic)
                            _InlineSubPicker(
                              options: const [('type_1', 'Type 1'), ('type_2', 'Type 2'), ('gestational', 'Gestational')],
                              selected: _diabetesType,
                              onSelect: (v) => setState(() => _diabetesType = v),
                              primaryColor: primaryColor,
                            ),
                          _ToggleRow(
                              label: 'Hypertension',
                              value: _hasHypertension,
                              onChanged: (v) =>
                                  setState(() => _hasHypertension = v),
                              primaryColor: primaryColor),
                          _ToggleRow(
                              label: 'Celiac disease',
                              value: _isCeliac,
                              onChanged: (v) =>
                                  setState(() => _isCeliac = v),
                              primaryColor: primaryColor),
                          _ToggleRow(
                              label: 'Lactose intolerant',
                              value: _isLactoseIntolerant,
                              onChanged: (v) => setState(() {
                                _isLactoseIntolerant = v;
                                if (!v) _lactoseLevel = '';
                              }),
                              primaryColor: primaryColor),
                          if (_isLactoseIntolerant)
                            _InlineSubPicker(
                              options: const [('mild', 'Mild — partial'), ('severe', 'Severe — zero lactose')],
                              selected: _lactoseLevel,
                              onSelect: (v) => setState(() => _lactoseLevel = v),
                              primaryColor: primaryColor,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dietary Preferences
                      _SectionCard(
                        title: 'Dietary Preferences',
                        icon: Icons.restaurant_outlined,
                        children: [
                          _ToggleRow(
                              label: 'Vegan',
                              value: _isVegan,
                              onChanged: (v) =>
                                  setState(() => _isVegan = v),
                              primaryColor: primaryColor),
                          _ToggleRow(
                              label: 'Vegetarian',
                              value: _isVegetarian,
                              onChanged: (v) =>
                                  setState(() => _isVegetarian = v),
                              primaryColor: primaryColor),
                          _ToggleRow(
                              label: 'Flexitarian',
                              value: _isFlexitarian,
                              onChanged: (v) =>
                                  setState(() => _isFlexitarian = v),
                              primaryColor: primaryColor),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Allergies
                      _SectionCard(
                        title: 'Allergies & Restrictions',
                        icon: Icons.warning_amber_outlined,
                        children: [
                          _buildLabel('List your allergies'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _allergiesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'e.g. peanuts, shellfish, gluten',
                              hintStyle: const TextStyle(
                                  color: Colors.grey, fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: primaryColor, width: 1.5),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nutritional Targets
                      _SectionCard(
                        title: 'Nutritional Targets (Optional)',
                        icon: Icons.track_changes_outlined,
                        children: [
                          Text(
                            'Leave blank to use auto-calculated values based on your profile.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Calories (kcal)'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                      controller: _caloriesController,
                                      hint: 'e.g. 2000',
                                      keyboardType: TextInputType.number),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Protein (g)'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                      controller: _proteinController,
                                      hint: 'e.g. 60',
                                      keyboardType: TextInputType.number),
                                ],
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Carbs (g)'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                      controller: _carbsController,
                                      hint: 'e.g. 250',
                                      keyboardType: TextInputType.number),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Fat (g)'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                      controller: _fatController,
                                      hint: 'e.g. 70',
                                      keyboardType: TextInputType.number),
                                ],
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Sugar limit (g)'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                      controller: _sugarController,
                                      hint: 'e.g. 50',
                                      keyboardType: TextInputType.number),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Salt limit (g)'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                      controller: _saltController,
                                      hint: 'e.g. 5',
                                      keyboardType: TextInputType.number),
                                ],
                              ),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              _isSaving ? null : () => _save(profile),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Save Profile',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF555555)));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(sub,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SegmentedRow extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String selected;
  final Function(String) onSelect;
  final Color primaryColor;

  const _SegmentedRow({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelect,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (i) {
        final isSelected = selected == options[i];
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(options[i]),
            child: Container(
              margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(labels[i],
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF888888))),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _GoalGrid extends StatelessWidget {
  final String selected;
  final Function(String) onSelect;
  final Color primaryColor;

  const _GoalGrid({
    required this.selected,
    required this.onSelect,
    required this.primaryColor,
  });

  static const goals = [
    ('lose_weight', 'Lose Weight', Icons.trending_down_rounded),
    ('gain_muscle', 'Gain Muscle', Icons.fitness_center),
    ('eat_healthy', 'Eat Healthy', Icons.eco_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: goals.map((g) {
        final isSelected = selected == g.$1;
        return GestureDetector(
          onTap: () => onSelect(g.$1),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withOpacity(0.1)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(g.$3,
                    size: 16,
                    color: isSelected ? primaryColor : Colors.grey),
                const SizedBox(width: 6),
                Text(g.$2,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? primaryColor
                            : const Color(0xFF888888))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActivityScoreWidget extends StatelessWidget {
  final String frequency;
  final String intensity;
  final String duration;
  final List<String> types;
  final String lifestyle;
  final Color primaryColor;
  final void Function(String) onFrequencyChange;
  final void Function(String) onIntensityChange;
  final void Function(String) onDurationChange;
  final void Function(List<String>) onTypesChange;
  final void Function(String) onLifestyleChange;

  const _ActivityScoreWidget({
    required this.frequency,
    required this.intensity,
    required this.duration,
    required this.types,
    required this.lifestyle,
    required this.primaryColor,
    required this.onFrequencyChange,
    required this.onIntensityChange,
    required this.onDurationChange,
    required this.onTypesChange,
    required this.onLifestyleChange,
  });

  static const _frequencies = [('0_1','0–1d'), ('2_3','2–3d'), ('4_5','4–5d'), ('6_7','6–7d')];
  static const _intensities = [
    ('low',      '🚶', 'Low',      'Walking, light yoga — easy conversation'),
    ('moderate', '🚴', 'Moderate', 'Jogging, cycling — slightly breathless'),
    ('high',     '🏃', 'High',     'HIIT, weight training — hard to talk'),
    ('extreme',  '⚡', 'Extreme',  'Competitive training — maximum effort'),
  ];
  static const _durations   = [('under_30','<30m'), ('30_60','30–60m'), ('60_90','60–90m'), ('over_90','90m+')];
  static const _types = [
    ('running','🏃','Running'), ('cycling','🚴','Cycling'), ('swimming','🏊','Swimming'),
    ('gym','🏋️','Gym'),       ('hiit','⚡','HIIT'),      ('football','⚽','Football'),
    ('yoga','🧘','Yoga'),      ('walking','🚶','Walking'),
  ];

  static const _lifestyles = [
    ('desk',     '🪑', 'Desk job',     'Mostly sitting — office, remote, studies'),
    ('mixed',    '🚶', 'Mixed',        'On feet part of the day — retail, teacher'),
    ('physical', '🔧', 'Physical job', 'Active all day — nurse, waiter, construction'),
  ];

  Widget _row(List<(String, String)> opts, String sel, void Function(String) onSel) {
    return Row(
      children: opts.map((o) {
        final on = sel == o.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSel(o.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 5),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: on ? primaryColor.withOpacity(0.1) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: on ? primaryColor : Colors.transparent, width: 1.5),
              ),
              child: Text(o.$2,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: on ? primaryColor : const Color(0xFF666666)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SubLabel('Days / week'),
        const SizedBox(height: 6),
        _row(_frequencies, frequency, onFrequencyChange),
        const SizedBox(height: 12),

        _SubLabel('Intensity'),
        const SizedBox(height: 6),
        ..._intensities.map((item) {
          final on = intensity == item.$1;
          return GestureDetector(
            onTap: () => onIntensityChange(item.$1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: on ? primaryColor.withOpacity(0.08) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: on ? primaryColor : Colors.transparent, width: 1.5),
              ),
              child: Row(children: [
                Text(item.$2, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$3, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: on ? primaryColor : const Color(0xFF1A1A1A))),
                    Text(item.$4, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  ],
                )),
                if (on) Icon(Icons.check_circle_rounded, color: primaryColor, size: 16),
              ]),
            ),
          );
        }),
        const SizedBox(height: 12),

        _SubLabel('Session duration'),
        const SizedBox(height: 6),
        _row(_durations, duration, onDurationChange),
        const SizedBox(height: 12),

        _SubLabel('Daily lifestyle (outside of exercise)'),
        const SizedBox(height: 6),
        ..._lifestyles.map((item) {
          final on = lifestyle == item.$1;
          return GestureDetector(
            onTap: () => onLifestyleChange(item.$1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: on ? primaryColor.withOpacity(0.08) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: on ? primaryColor : Colors.transparent, width: 1.5),
              ),
              child: Row(children: [
                Text(item.$2, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$3, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: on ? primaryColor : const Color(0xFF1A1A1A))),
                    Text(item.$4, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  ],
                )),
                if (on) Icon(Icons.check_circle_rounded, color: primaryColor, size: 16),
              ]),
            ),
          );
        }),
        const SizedBox(height: 12),

        _SubLabel('Type of activity'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _types.map((t) {
            final on = types.contains(t.$1);
            return GestureDetector(
              onTap: () {
                final updated = List<String>.from(types);
                on ? updated.remove(t.$1) : updated.add(t.$1);
                onTypesChange(updated);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: on ? primaryColor.withOpacity(0.1) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: on ? primaryColor : Colors.transparent, width: 1.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.$2, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(t.$3, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: on ? primaryColor : const Color(0xFF555555))),
                ]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _InlineSubPicker extends StatelessWidget {
  final List<(String, String)> options;
  final String selected;
  final void Function(String) onSelect;
  final Color primaryColor;
  const _InlineSubPicker({required this.options, required this.selected, required this.onSelect, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 2),
      child: Wrap(
        spacing: 8,
        children: options.map((o) {
          final on = selected == o.$1;
          return GestureDetector(
            onTap: () => onSelect(o.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: on ? primaryColor.withOpacity(0.1) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: on ? primaryColor : Colors.transparent, width: 1.5),
              ),
              child: Text(o.$2,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: on ? primaryColor : const Color(0xFF666666))),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black45));
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool) onChanged;
  final Color primaryColor;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF444444))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }
}