import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const primaryColor = Color(0xFFEC6F2D);
  static const totalSteps = 3;

  final _pageController = PageController();
  int _step = 0;
  bool _saving = false;
  String? _error;

  // Step 1
  String _gender = 'male';
  DateTime? _dateOfBirth;
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  // Step 2
  String _goal = 'eat_healthy';
  String _activityFrequency = '2_3';
  String _activityIntensity = 'moderate';
  String _activityDuration = '30_60';
  List<String> _activityTypes = [];
  String _lifestyle = 'desk';

  // Step 3
  bool _isDiabetic = false;
  String _diabetesType = '';
  bool _hasHypertension = false;
  bool _isCeliac = false;
  bool _isLactoseIntolerant = false;
  String _lactoseLevel = '';
  bool _isVegan = false;
  bool _isVegetarian = false;
  bool _isFlexitarian = false;
  final _allergiesCtrl = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _allergiesCtrl.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (_step == 0) {
      final weight = double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));
      final height = double.tryParse(_heightCtrl.text.trim().replaceAll(',', '.'));
      if (weight == null || height == null) {
        setState(() => _error = 'Please enter your weight and height.');
        return;
      }
      if (weight < 20 || weight > 300) {
        setState(() => _error = 'Please enter a valid weight (20–300 kg).');
        return;
      }
      if (height < 50 || height > 250) {
        setState(() => _error = 'Please enter a valid height (50–250 cm).');
        return;
      }
      if (_dateOfBirth != null) {
        final age = DateTime.now().difference(_dateOfBirth!).inDays ~/ 365;
        if (age < 16) {
          setState(() => _error = 'You must be at least 16 years old to use NutriLens.');
          return;
        }
        if (age > 120) {
          setState(() => _error = 'Please enter a valid date of birth.');
          return;
        }
      }
    }

    if (_step < totalSteps - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() {
        _step--;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final service = ref.read(authServiceProvider);
      final data = <String, dynamic>{
        'profile': {
          'gender': _gender,
          if (_dateOfBirth != null)
            'date_of_birth': DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
          'weight': double.parse(_weightCtrl.text.trim().replaceAll(',', '.')),
          'height': double.parse(_heightCtrl.text.trim().replaceAll(',', '.')),
          'goal': _goal,
          'activity_frequency': _activityFrequency,
          'activity_intensity': _activityIntensity,
          'activity_duration': _activityDuration,
          'activity_types': _activityTypes.join(','),
          'lifestyle': _lifestyle,
          'is_diabetic': _isDiabetic,
          'diabetes_type': _diabetesType,
          'lactose_intolerance_level': _lactoseLevel,
          'has_hypertension': _hasHypertension,
          'is_celiac': _isCeliac,
          'is_lactose_intolerant': _isLactoseIntolerant,
          'is_vegan': _isVegan,
          'is_vegetarian': _isVegetarian,
          'is_flexitarian': _isFlexitarian,
          'allergies': _allergiesCtrl.text.trim(),
        }
      };
      final user = await service.updateProfile(data: data);
      ref.read(authStateProvider.notifier).updateUser(user);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          _back();
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          if (_step > 0)
            GestureDetector(
              onTap: _back,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left, size: 22, color: Colors.black54),
              ),
            )
          else
            const SizedBox(width: 36),
          const Spacer(),
          Image.asset('assets/images/logo.png', height: 28),
          const Spacer(),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(totalSteps, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i <= _step ? primaryColor : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_step + 1} of $totalSteps',
            style: const TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryColor.withOpacity(0.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      _step == totalSteps - 1 ? 'Complete Setup' : 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Basic Info ────────────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell us about yourself',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('This helps us personalize your nutrition targets.',
              style: TextStyle(fontSize: 14, color: Colors.black45)),
          const SizedBox(height: 28),

          // Gender
          const _Label('Gender'),
          const SizedBox(height: 8),
          Row(
            children: [
              _SelectTile(
                label: 'Male',
                icon: Icons.male_rounded,
                selected: _gender == 'male',
                onTap: () => setState(() => _gender = 'male'),
              ),
              const SizedBox(width: 12),
              _SelectTile(
                label: 'Female',
                icon: Icons.female_rounded,
                selected: _gender == 'female',
                onTap: () => setState(() => _gender = 'female'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Date of birth
          const _Label('Date of birth (optional)'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black38),
                  const SizedBox(width: 10),
                  Text(
                    _dateOfBirth != null
                        ? DateFormat('MMMM d, yyyy').format(_dateOfBirth!)
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 15,
                      color: _dateOfBirth != null ? const Color(0xFF1A1A1A) : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Weight & Height
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Weight (kg)'),
                    const SizedBox(height: 8),
                    _NumberField(controller: _weightCtrl, hint: '70'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Height (cm)'),
                    const SizedBox(height: 8),
                    _NumberField(controller: _heightCtrl, hint: '175'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 120)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Widget _buildHorizPicker({
    required List<(String, String)> options,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Row(
      children: options.map((o) {
        final isSelected = selected == o.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(o.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withOpacity(0.1) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? primaryColor : Colors.transparent, width: 1.5),
              ),
              child: Text(o.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: isSelected ? primaryColor : const Color(0xFF666666))),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Step 2: Goal & Activity ───────────────────────────────────────────────

  Widget _buildStep2() {
    const goals = [
      ('lose_weight', 'Lose Weight', Icons.trending_down_rounded, 'Reduce body fat'),
      ('gain_muscle', 'Gain Muscle', Icons.fitness_center_rounded, 'Build strength'),
      ('eat_healthy', 'Eat Healthy', Icons.eco_rounded, 'Improve overall diet'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your goal',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('We use this to calculate your daily calorie target.',
              style: TextStyle(fontSize: 14, color: Colors.black45)),
          const SizedBox(height: 24),

          ...goals.map((g) {
            final (value, label, icon, subtitle) = g;
            final selected = _goal == value;
            return GestureDetector(
              onTap: () => setState(() => _goal = value),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? primaryColor.withOpacity(0.08) : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? primaryColor : Colors.transparent, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: selected ? primaryColor : Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: selected ? Colors.white : Colors.black45, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                              color: selected ? primaryColor : const Color(0xFF1A1A1A))),
                          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                        ],
                      ),
                    ),
                    if (selected) const Icon(Icons.check_circle_rounded, color: primaryColor, size: 20),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          const Text('Physical activity',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Be specific — this directly affects your calorie target.',
              style: TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 16),

          // Frequency
          const _Label('How many days per week do you exercise?'),
          const SizedBox(height: 8),
          _buildHorizPicker(
            options: const [('0_1', '0–1 days'), ('2_3', '2–3 days'), ('4_5', '4–5 days'), ('6_7', '6–7 days')],
            selected: _activityFrequency,
            onSelect: (v) => setState(() => _activityFrequency = v),
          ),
          const SizedBox(height: 16),

          // Intensity
          const _Label('What is your usual intensity?'),
          const SizedBox(height: 8),
          ..._kIntensities.map((item) {
            final selected = _activityIntensity == item.$1;
            return GestureDetector(
              onTap: () => setState(() => _activityIntensity = item.$1),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? primaryColor.withOpacity(0.08) : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? primaryColor : Colors.transparent, width: 1.5),
                ),
                child: Row(children: [
                  Text(item.$2, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$3, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: selected ? primaryColor : const Color(0xFF1A1A1A))),
                      Text(item.$4, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                    ],
                  )),
                  if (selected) Icon(Icons.check_circle_rounded, color: primaryColor, size: 18),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),

          // Duration
          const _Label('Average session duration?'),
          const SizedBox(height: 8),
          _buildHorizPicker(
            options: const [('under_30', '< 30 min'), ('30_60', '30–60 min'), ('60_90', '60–90 min'), ('over_90', '90+ min')],
            selected: _activityDuration,
            onSelect: (v) => setState(() => _activityDuration = v),
          ),
          const SizedBox(height: 16),

          // Activity types
          const _Label('Types of activity (select all that apply)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kActivityTypes.map((item) {
              final selected = _activityTypes.contains(item.$1);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _activityTypes = _activityTypes.where((t) => t != item.$1).toList();
                  } else {
                    _activityTypes = [..._activityTypes, item.$1];
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? primaryColor.withOpacity(0.1) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? primaryColor : Colors.transparent, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.$2, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(item.$3,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                              color: selected ? primaryColor : const Color(0xFF555555))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Lifestyle (NEAT)
          const _Label('Daily lifestyle (outside of exercise)'),
          const SizedBox(height: 8),
          ..._kLifestyles.map((item) {
            final selected = _lifestyle == item.$1;
            return GestureDetector(
              onTap: () => setState(() => _lifestyle = item.$1),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? primaryColor.withOpacity(0.08) : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? primaryColor : Colors.transparent, width: 1.5),
                ),
                child: Row(children: [
                  Text(item.$2, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$3, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: selected ? primaryColor : const Color(0xFF1A1A1A))),
                      Text(item.$4, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                    ],
                  )),
                  if (selected) Icon(Icons.check_circle_rounded, color: primaryColor, size: 18),
                ]),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Step 3: Medical Conditions ────────────────────────────────────────────

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Health & Diet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('Select any that apply. NutriLens will adapt its recommendations accordingly.',
              style: TextStyle(fontSize: 14, color: Colors.black45)),
          const SizedBox(height: 24),

          const _Label('Medical conditions'),
          const SizedBox(height: 10),
          _ConditionTile(
            label: 'Diabetes',
            subtitle: 'Monitor sugar & carb intake',
            icon: Icons.water_drop_outlined,
            value: _isDiabetic,
            onChanged: (v) => setState(() {
              _isDiabetic = v;
              if (!v) _diabetesType = '';
            }),
          ),
          if (_isDiabetic)
            _SubPicker(
              options: const [('type_1', 'Type 1'), ('type_2', 'Type 2'), ('gestational', 'Gestational')],
              selected: _diabetesType,
              onSelect: (v) => setState(() => _diabetesType = v),
            ),
          _ConditionTile(
            label: 'Hypertension',
            subtitle: 'Track sodium & salt levels',
            icon: Icons.favorite_border_rounded,
            value: _hasHypertension,
            onChanged: (v) => setState(() => _hasHypertension = v),
          ),
          _ConditionTile(
            label: 'Celiac disease',
            subtitle: 'Alert on gluten-containing products',
            icon: Icons.grain_rounded,
            value: _isCeliac,
            onChanged: (v) => setState(() => _isCeliac = v),
          ),
          _ConditionTile(
            label: 'Lactose intolerant',
            subtitle: 'Flag dairy products',
            icon: Icons.no_drinks_outlined,
            value: _isLactoseIntolerant,
            onChanged: (v) => setState(() {
              _isLactoseIntolerant = v;
              if (!v) _lactoseLevel = '';
            }),
          ),
          if (_isLactoseIntolerant)
            _SubPicker(
              options: const [('mild', 'Mild — partial tolerance'), ('severe', 'Severe — zero lactose')],
              selected: _lactoseLevel,
              onSelect: (v) => setState(() => _lactoseLevel = v),
            ),

          const SizedBox(height: 20),
          const _Label('Dietary preferences'),
          const SizedBox(height: 10),
          _ConditionTile(
            label: 'Vegan',
            subtitle: 'No animal products',
            icon: Icons.eco_outlined,
            value: _isVegan,
            onChanged: (v) => setState(() => _isVegan = v),
          ),
          _ConditionTile(
            label: 'Vegetarian',
            subtitle: 'No meat or fish',
            icon: Icons.spa_outlined,
            value: _isVegetarian,
            onChanged: (v) => setState(() => _isVegetarian = v),
          ),
          _ConditionTile(
            label: 'Flexitarian',
            subtitle: 'Mostly plant-based, occasionally meat',
            icon: Icons.restaurant_outlined,
            value: _isFlexitarian,
            onChanged: (v) => setState(() => _isFlexitarian = v),
          ),

          const SizedBox(height: 20),
          const _Label('Other allergies (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _allergiesCtrl,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. peanuts, shellfish, soy...',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Activity helpers ──────────────────────────────────────────────────────────

const _kLifestyles = [
  ('desk',     '🪑', 'Desk job',     'Mostly sitting — office, remote work, studies'),
  ('mixed',    '🚶', 'Mixed',        'On your feet part of the day — retail, teacher'),
  ('physical', '🔧', 'Physical job', 'Active all day — nurse, waiter, construction'),
];

const _kIntensities = [
  ('low',      '🚶', 'Low',      'Walking, light yoga — easy conversation'),
  ('moderate', '🚴', 'Moderate', 'Jogging, cycling — slightly breathless'),
  ('high',     '🏃', 'High',     'HIIT, weight training — hard to talk'),
  ('extreme',  '⚡', 'Extreme',  'Competitive training — maximum effort'),
];

const _kActivityTypes = [
  ('running',  '🏃', 'Running'),
  ('cycling',  '🚴', 'Cycling'),
  ('swimming', '🏊', 'Swimming'),
  ('gym',      '🏋️', 'Gym'),
  ('hiit',     '⚡', 'HIIT'),
  ('football', '⚽', 'Football'),
  ('yoga',     '🧘', 'Yoga'),
  ('walking',  '🚶', 'Walking'),
];

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SubPicker extends StatelessWidget {
  final List<(String, String)> options;
  final String selected;
  final void Function(String) onSelect;
  const _SubPicker({required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFEC6F2D);
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: Column(
        children: options.map((o) {
          final on = selected == o.$1;
          return GestureDetector(
            onTap: () => onSelect(o.$1),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: on ? primary.withOpacity(0.08) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: on ? primary : Colors.transparent, width: 1.5),
              ),
              child: Row(children: [
                Expanded(child: Text(o.$2,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                        color: on ? primary : const Color(0xFF555555)))),
                if (on) const Icon(Icons.check_circle_rounded, color: primary, size: 16),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
      );
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _NumberField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

class _SelectTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SelectTile(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFEC6F2D);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? primary.withOpacity(0.08) : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? primary : Colors.black38, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: selected ? primary : Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ConditionTile(
      {required this.label,
      required this.subtitle,
      required this.icon,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFEC6F2D);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value ? primary.withOpacity(0.06) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: value ? primary.withOpacity(0.12) : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: value ? primary : Colors.black38, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: value ? primary : const Color(0xFF1A1A1A))),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: primary,
            ),
          ],
        ),
      ),
    );
  }
}
