import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/inventory/providers/inventory_provider.dart';
import '../../../core/network/api_client.dart';
import '../../scanner/providers/scan_history_provider.dart';
import '../../scanner/models/scan_history_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final inventoryState = ref.watch(inventoryProvider);
    final scanHistory = ref.watch(scanHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEC6F2D), Color(0xFFFF6B35)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 76, 24, 46),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildUserAvatar(user?.profile.avatar, user?.username),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Good morning,',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              Text(user?.username ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () =>
                            ref.read(authStateProvider.notifier).logout(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2),
                          ),
                          child: const Icon(Icons.logout,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Scan button
                    GestureDetector(
                      onTap: () => context.push('/scanner'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC6F2D), Color(0xFFFF6B35)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner,
                                color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text('Scan Product',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Quick access cards
                    Row(
                        children: [
                            Expanded(
                                child: _QuickCard(
                                    icon: Icons.inventory_2_outlined,
                                    label: 'Food Inventory',
                                    subtitle: inventoryState.whenOrNull(
                                        data: (items) => '${items.length} items',
                                        ) ?? '...',
                                    onTap: () => context.push('/inventory'),
                                ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _QuickCard(
                                    icon: Icons.account_balance_wallet_outlined,
                                    label: 'Budget',
                                    subtitle: '\$165 left',
                                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Coming soon!'))),
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                        children: [
                            Expanded(
                            child: _QuickCard(
                                icon: Icons.bar_chart_rounded,
                                label: 'Reports',
                                subtitle: 'Weekly stats',
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Coming in Sprint 2!'))),
                            ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                            child: _QuickCard(
                                icon: Icons.smart_toy_outlined,
                                label: 'AI Coach',
                                subtitle: 'Get advice',
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Coming in Sprint 3!'))),
                            ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 16),

                    // Today's summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Today's Summary",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 16),
                          _SummaryRow(
                              icon: Icons.local_fire_department,
                              label: 'Calories',
                              value: '1,450 / 2,000',
                              progress: 0.72),
                          const SizedBox(height: 12),
                          _SummaryRow(
                              icon: Icons.water_drop_outlined,
                              label: 'Sugar',
                              value: '24g / 50g',
                              progress: 0.48),
                          const SizedBox(height: 12),
                          _SummaryRow(
                              icon: Icons.fitness_center,
                              label: 'Protein',
                              value: '45g / 60g',
                              progress: 0.75),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recent scans
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Recent Scans',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A))),
                              TextButton(
                                onPressed: () => context.push('/history'),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                child: Text('View All',
                                    style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          scanHistory.when(
                            loading: () => const Center(
                                child: CircularProgressIndicator(
                                    color: primaryColor, strokeWidth: 2)),
                            error: (_, __) => const Text('Unable to load scans',
                                style: TextStyle(color: Colors.grey, fontSize: 13)),
                            data: (scans) {
                              if (scans.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                      'No scans yet — scan your first product!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 13)),
                                );
                              }
                              return Column(
                                children: scans.take(3).map((scan) => _RecentScanItem(
                                  name: scan.name,
                                  time: _timeAgo(scan.scannedAt),
                                  score: scan.nutriscore?.toUpperCase() ?? '?',
                                  imageUrl: scan.imageUrl,
                                  brand: scan.brand,
                                )).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      active: true),
                  _NavItem(
                      icon: Icons.history,
                      label: 'History',
                      onTap: () => context.push('/history')),
                  // Scanner central button
                  GestureDetector(
                    onTap: () => context.push('/scanner'),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFEC6F2D), Color(0xFFFF6B35)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_scanner,
                          color: Colors.white, size: 24),
                    ),
                  ),
                  _NavItem(icon: Icons.chat_bubble_outline, label: 'Chat'),
                  _NavItem(
                      icon: Icons.person_outline,
                      label: 'Profile',
                      onTap: () => context.push('/profile')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildUserAvatar(String? avatar, String? username) {
  final initial = username != null && username.isNotEmpty
      ? username[0].toUpperCase()
      : '?';
  return Container(
    width: 54,
    height: 54,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
    ),
    child: ClipOval(
      child: avatar != null && avatar.isNotEmpty
          ? Image.network(
              avatar.startsWith('http')
                  ? avatar
                  : '${ApiClient.baseUrl.replaceAll('/api', '')}$avatar',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildInitialAvatar(initial),
            )
          : _buildInitialAvatar(initial),
    ),
  );
}

Widget _buildInitialAvatar(String initial) {
  return Container(
    color: Colors.white.withOpacity(0.25),
    child: Center(
      child: Text(initial,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
    ),
  );
}


Widget _buildScanPlaceholder() {
  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: const Color(0xFFEEEEEE),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.fastfood_rounded, color: Colors.grey, size: 20),
  );
}

Color _scoreColor(String s) {
  switch (s.toUpperCase()) {
    case 'A': return const Color(0xFF1E8449);
    case 'B': return const Color(0xFF58D68D);
    case 'C': return const Color(0xFFF4D03F);
    case 'D': return const Color(0xFFE67E22);
    case 'E': return const Color(0xFFE74C3C);
    default: return Colors.grey;
  }
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays} days ago';
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double progress;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
  });

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
        ),
        SizedBox(
          width: 64,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor:
                  const AlwaysStoppedAnimation(primaryColor),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentScanItem extends StatelessWidget {
  final String name;
  final String time;
  final String score;
  final String? imageUrl;
  final String? brand;

  const _RecentScanItem({
    required this.name,
    required this.time,
    required this.score,
    this.imageUrl,
    this.brand,
  });

  Color _scoreColor(String s) {
    switch (s) {
      case 'A': return const Color(0xFF1E8449);
      case 'B': return const Color(0xFF58D68D);
      case 'C': return const Color(0xFFF4D03F);
      case 'D': return const Color(0xFFE67E22);
      case 'E': return const Color(0xFFE74C3C);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildScanPlaceholder(),
                  )
                : _buildScanPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
                if (brand != null && brand!.isNotEmpty)
                  Text(brand!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                Text(time,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _scoreColor(score),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(score,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: active ? primaryColor : Colors.grey, size: 24),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: active ? primaryColor : Colors.grey,
                fontWeight: active
                    ? FontWeight.w600
                    : FontWeight.w400)),
      ],
      ),
    );
  }
}