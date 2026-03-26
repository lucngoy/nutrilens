import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/network/api_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const SizedBox();

    final profile = user.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 16, 24, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
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
                  const Text('Profile',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A))),
                ],
              ),
            ),

            // Avatar + nom + email
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: primaryColor.withOpacity(0.2), width: 3),
                          ),
                          child: ClipOval(
                            child: profile.avatar != null && profile.avatar!.isNotEmpty
                                ? Image.network(
                                    profile.avatar!.startsWith('http')
                                        ? profile.avatar!
                                        : '${ApiClient.baseUrl.replaceAll('/api', '')}${profile.avatar!}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildAvatarFallback(user),
                                  )
                                : _buildAvatarFallback(user),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.username,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),

                  // Goal badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_goalIcon(profile.goal),
                            size: 16, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(_goalLabel(profile.goal),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stats santé
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HEALTH STATS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 0.08)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              label: 'Weight',
                              value: profile.weight != null
                                  ? '${profile.weight!.toStringAsFixed(1)} kg'
                                  : '—',
                              icon: Icons.monitor_weight_outlined)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                              label: 'Height',
                              value: profile.height != null
                                  ? '${profile.height!.toStringAsFixed(0)} cm'
                                  : '—',
                              icon: Icons.height)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                              label: 'BMI',
                              value: profile.bmi != null
                                  ? profile.bmi!.toStringAsFixed(1)
                                  : '—',
                              icon: Icons.analytics_outlined,
                              valueColor: _bmiColor(profile.bmi))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Conditions médicales
            if (profile.isDiabetic ||
                profile.hasHypertension ||
                profile.isCeliac ||
                profile.allergies.isNotEmpty)
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HEALTH CONDITIONS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 0.08)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (profile.isDiabetic)
                          _ConditionBadge(label: 'Diabetic'),
                        if (profile.hasHypertension)
                          _ConditionBadge(label: 'Hypertension'),
                        if (profile.isCeliac)
                          _ConditionBadge(label: 'Celiac'),
                        if (profile.allergies.isNotEmpty)
                          ...profile.allergies
                              .split(',')
                              .where((a) => a.trim().isNotEmpty)
                              .map((a) => _ConditionBadge(
                                  label: a.trim(), isAllergy: true)),
                      ],
                    ),
                  ],
                ),
              ),
            if (profile.isDiabetic ||
                profile.hasHypertension ||
                profile.isCeliac ||
                profile.allergies.isNotEmpty)
              const SizedBox(height: 12),

            // Settings menu
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SETTINGS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 0.08)),
                  const SizedBox(height: 12),
                  _MenuItem(
                    icon: Icons.person_outline,
                    label: 'Personal Information',
                    description: 'Name, email',
                    onTap: () => _showEditPersonalInfo(context, user),
                  ),
                  _MenuItem(
                    icon: Icons.eco_outlined,
                    label: 'Health Preferences',
                    description: 'Goal, weight, height, conditions',
                    onTap: () => _showEditHealthPrefs(context, profile),
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    description: 'Push notifications, reminders',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!'))),
                  ),
                  _MenuItem(
                    icon: Icons.shield_outlined,
                    label: 'Privacy & Security',
                    description: 'Password, data settings',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!'))),
                  ),
                  _MenuItem(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    description: 'FAQ, contact us',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!'))),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEEEEEE)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Sign Out',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Version
            const Text('NutriLens v1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(UserModel user) {
    return Container(
      color: primaryColor,
      child: Center(
        child: Text(
          user.username[0].toUpperCase(),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    try {
      final authService = ref.read(authServiceProvider);
      final updatedUser = await authService.uploadAvatar(File(picked.path));
      ref.read(authStateProvider.notifier).updateUser(updatedUser);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  // Edit Personal Info bottom sheet
  void _showEditPersonalInfo(BuildContext context, UserModel user) {
    final usernameController =
        TextEditingController(text: user.username);
    final emailController = TextEditingController(text: user.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Information',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _EditField(
                controller: usernameController, label: 'Username'),
            const SizedBox(height: 12),
            _EditField(controller: emailController, label: 'Email'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // TODO: appel PATCH /users/profile/
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profile updated!'),
                          backgroundColor: Colors.green));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Edit Health Preferences bottom sheet
  void _showEditHealthPrefs(BuildContext context, UserProfile profile) {
    final weightController = TextEditingController(
        text: profile.weight?.toString() ?? '');
    final heightController = TextEditingController(
        text: profile.height?.toString() ?? '');
    final allergiesController =
        TextEditingController(text: profile.allergies);
    String selectedGoal = profile.goal;
    bool isDiabetic = profile.isDiabetic;
    bool hasHypertension = profile.hasHypertension;
    bool isCeliac = profile.isCeliac;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Health Preferences',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              // Goal selector
              const Text('Goal',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'lose_weight',
                  'gain_muscle',
                  'maintain',
                  'eat_healthy'
                ].map((g) {
                  final selected = selectedGoal == g;
                  return GestureDetector(
                    onTap: () =>
                        setModalState(() => selectedGoal = g),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? primaryColor
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_goalLabel(g),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Weight + Height
              Row(children: [
                Expanded(
                    child: _EditField(
                        controller: weightController,
                        label: 'Weight (kg)',
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    child: _EditField(
                        controller: heightController,
                        label: 'Height (cm)',
                        keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 16),

              // Conditions
              const Text('Medical Conditions',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              _SwitchRow(
                  label: 'Diabetic',
                  value: isDiabetic,
                  onChanged: (v) =>
                      setModalState(() => isDiabetic = v)),
              _SwitchRow(
                  label: 'Hypertension',
                  value: hasHypertension,
                  onChanged: (v) =>
                      setModalState(() => hasHypertension = v)),
              _SwitchRow(
                  label: 'Celiac',
                  value: isCeliac,
                  onChanged: (v) =>
                      setModalState(() => isCeliac = v)),
              const SizedBox(height: 16),

              // Allergies
              _EditField(
                  controller: allergiesController,
                  label: 'Allergies (comma separated)',
                  hint: 'e.g. nuts, dairy, gluten'),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveHealthPrefs(
                      context: context,
                      goal: selectedGoal,
                      weight: double.tryParse(weightController.text),
                      height: double.tryParse(heightController.text),
                      isDiabetic: isDiabetic,
                      hasHypertension: hasHypertension,
                      isCeliac: isCeliac,
                      allergies: allergiesController.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('Save',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveHealthPrefs({
    required BuildContext context,
    required String goal,
    double? weight,
    double? height,
    required bool isDiabetic,
    required bool hasHypertension,
    required bool isCeliac,
    required String allergies,
  }) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateProfile(data: {
        'profile': {
          'goal': goal,
          'weight': weight,
          'height': height,
          'is_diabetic': isDiabetic,
          'has_hypertension': hasHypertension,
          'is_celiac': isCeliac,
          'allergies': allergies,
        }
      });

      final updatedUser = await authService.getProfile();

      if (context.mounted) Navigator.pop(context);

      ref.read(authStateProvider.notifier).updateUser(updatedUser);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()),
                backgroundColor: Colors.red));
      }
    }
  }

  IconData _goalIcon(String goal) {
    switch (goal) {
      case 'lose_weight': return Icons.trending_down;
      case 'gain_muscle': return Icons.fitness_center;
      case 'maintain': return Icons.balance;
      case 'eat_healthy': return Icons.eco_outlined;
      default: return Icons.flag_outlined;
    }
  }

  String _goalLabel(String goal) {
    switch (goal) {
      case 'lose_weight': return 'Lose Weight';
      case 'gain_muscle': return 'Gain Muscle';
      case 'maintain': return 'Maintain';
      case 'eat_healthy': return 'Eat Healthy';
      default: return goal;
    }
  }

  Color _bmiColor(double? bmi) {
    if (bmi == null) return Colors.grey;
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return const Color(0xFF27AE60);
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}

// Widgets helpers
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? const Color(0xFF1A1A1A))),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ConditionBadge extends StatelessWidget {
  final String label;
  final bool isAllergy;

  const _ConditionBadge({required this.label, this.isAllergy = false});

  @override
  Widget build(BuildContext context) {
    final color =
        isAllergy ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              isAllergy
                  ? Icons.warning_amber_rounded
                  : Icons.medical_services_outlined,
              size: 12,
              color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.isLast = false,
  });

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A))),
                      Text(description,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;

  const _EditField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFEC6F2D), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF1A1A1A))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFEC6F2D),
          ),
        ],
      ),
    );
  }
}