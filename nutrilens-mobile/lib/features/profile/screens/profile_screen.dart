import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../health/providers/health_provider.dart';
import '../../../core/network/api_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const primaryColor = Color(0xFFEC6F2D);
  bool _uploadingAvatar = false;
  File? _pendingAvatar;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const SizedBox();

    final healthState = ref.watch(healthProfileProvider);
    final healthProfile = healthState.valueOrNull;
    final isHealthLoading = healthState.isLoading;

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
                    onTap: () => context.canPop() ? context.pop() : context.go('/home'),
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
                    onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
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
                            child: _pendingAvatar != null
                                ? Image.file(_pendingAvatar!, fit: BoxFit.cover)
                                : user.profile.avatar != null && user.profile.avatar!.isNotEmpty
                                    ? Image.network(
                                        user.profile.avatar!.startsWith('http')
                                            ? user.profile.avatar!
                                            : '${ApiClient.baseUrl.replaceAll('/api', '')}${user.profile.avatar!}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildAvatarFallback(user),
                                      )
                                    : _buildAvatarFallback(user),
                          ),
                        ),
                        if (_uploadingAvatar)
                          Positioned.fill(
                            child: ClipOval(
                              child: Container(
                                color: Colors.black.withOpacity(0.45),
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (!_uploadingAvatar)
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
                  if (healthProfile != null)
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
                          Icon(_goalIcon(healthProfile.goal),
                              size: 16, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(_goalLabel(healthProfile.goal),
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
                  if (isHealthLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                            child: _StatCard(
                                label: 'Weight',
                                value: healthProfile?.weight != null
                                    ? '${healthProfile!.weight!.toStringAsFixed(1)} kg'
                                    : '—',
                                icon: Icons.monitor_weight_outlined)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _StatCard(
                                label: 'Height',
                                value: healthProfile?.height != null
                                    ? '${healthProfile!.height!.toStringAsFixed(0)} cm'
                                    : '—',
                                icon: Icons.height)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _StatCard(
                                label: 'BMI',
                                value: healthProfile?.bmi != null
                                    ? healthProfile!.bmi!.toStringAsFixed(1)
                                    : '—',
                                icon: Icons.analytics_outlined,
                                valueColor: _bmiColor(healthProfile?.bmi))),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Conditions médicales
            if (healthProfile != null &&
                (healthProfile.isDiabetic ||
                    healthProfile.hasHypertension ||
                    healthProfile.isCeliac ||
                    healthProfile.allergies.isNotEmpty))
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
                        if (healthProfile.isDiabetic)
                          _ConditionBadge(label: 'Diabetic'),
                        if (healthProfile.hasHypertension)
                          _ConditionBadge(label: 'Hypertension'),
                        if (healthProfile.isCeliac)
                          _ConditionBadge(label: 'Celiac'),
                        if (healthProfile.allergies.isNotEmpty)
                          ...healthProfile.allergies
                              .split(',')
                              .where((a) => a.trim().isNotEmpty)
                              .map((a) => _ConditionBadge(
                                  label: a.trim(), isAllergy: true)),
                      ],
                    ),
                  ],
                ),
              ),
            if (healthProfile != null &&
                (healthProfile.isDiabetic ||
                    healthProfile.hasHypertension ||
                    healthProfile.isCeliac ||
                    healthProfile.allergies.isNotEmpty))
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
                    onTap: () => context.push('/health-profile'),
                  ),
                  _MenuItem(
                    icon: Icons.history,
                    label: 'Health History',
                    description: 'Weight, BMI & calorie tracking over time',
                    onTap: () => context.push('/health-history'),
                  ),
                  _MenuItem(
                    icon: Icons.folder_outlined,
                    label: 'Medical Documents',
                    description: 'Lab results, prescriptions, reports',
                    onTap: () => context.push('/medical-documents'),
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    description: 'Push notifications, reminders',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!'))),
                  ),
                  _MenuItem(
                    icon: Icons.lock_outline,
                    label: 'Change Password',
                    description: 'Update your password',
                    onTap: () => _showChangePassword(context),
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

    final file = File(picked.path);
    setState(() {
      _uploadingAvatar = true;
      _pendingAvatar = file;
    });

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      // Evict old avatar from Flutter's image cache
      if (user?.profile.avatar != null && user!.profile.avatar!.isNotEmpty) {
        final oldUrl = user.profile.avatar!.startsWith('http')
            ? user.profile.avatar!
            : '${ApiClient.baseUrl.replaceAll('/api', '')}${user.profile.avatar!}';
        NetworkImage(oldUrl).evict();
      }

      final authService = ref.read(authServiceProvider);
      final updatedUser = await authService.uploadAvatar(file);
      ref.read(authStateProvider.notifier).updateUser(updatedUser);
    } catch (e) {
      if (mounted) {
        setState(() => _pendingAvatar = null);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showEditPersonalInfo(BuildContext context, UserModel user) {
    final usernameController = TextEditingController(text: user.username);
    final emailController = TextEditingController(text: user.email);
    bool saving = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _EditField(controller: usernameController, label: 'Username'),
              const SizedBox(height: 12),
              _EditField(
                  controller: emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFE74C3C).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFE74C3C), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(errorMessage!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE74C3C))),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setSheetState(() {
                            saving = true;
                            errorMessage = null;
                          });
                          try {
                            final authService = ref.read(authServiceProvider);
                            final updated =
                                await authService.updateProfile(data: {
                              'username': usernameController.text.trim(),
                              'email': emailController.text.trim(),
                            });
                            ref
                                .read(authStateProvider.notifier)
                                .updateUser(updated);
                            if (context.mounted) {
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Profile updated!'),
                                      backgroundColor: Colors.green));
                            }
                          } catch (e) {
                            setSheetState(() {
                              saving = false;
                              errorMessage = e.toString();
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save',
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

  void _showChangePassword(BuildContext context) {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool saving = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Change Password',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _EditField(
                  controller: oldController,
                  label: 'Current Password',
                  obscure: true),
              const SizedBox(height: 12),
              _EditField(
                  controller: newController,
                  label: 'New Password',
                  hint: 'At least 8 characters',
                  obscure: true),
              const SizedBox(height: 12),
              _EditField(
                  controller: confirmController,
                  label: 'Confirm New Password',
                  obscure: true),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFE74C3C).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFE74C3C), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(errorMessage!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE74C3C))),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (newController.text != confirmController.text) {
                            setSheetState(
                                () => errorMessage = 'Passwords do not match.');
                            return;
                          }
                          setSheetState(() {
                            saving = true;
                            errorMessage = null;
                          });
                          try {
                            final authService = ref.read(authServiceProvider);
                            await authService.changePassword(
                              oldPassword: oldController.text,
                              newPassword: newController.text,
                            );
                            if (context.mounted) {
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Password updated!'),
                                      backgroundColor: Colors.green));
                            }
                          } catch (e) {
                            setSheetState(() {
                              saving = false;
                              errorMessage = e.toString();
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Update Password',
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
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

class _EditField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;

  const _EditField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.obscure = false,
  });

  @override
  State<_EditField> createState() => _EditFieldState();
}

class _EditFieldState extends State<_EditField> {
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _hidden,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                const TextStyle(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
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
