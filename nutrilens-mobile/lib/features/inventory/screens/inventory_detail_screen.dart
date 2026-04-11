import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../models/inventory_model.dart';
import '../providers/inventory_provider.dart';

class InventoryDetailScreen extends ConsumerStatefulWidget {
  final InventoryItem item;
  const InventoryDetailScreen({super.key, required this.item});

  @override
  ConsumerState<InventoryDetailScreen> createState() =>
      _InventoryDetailScreenState();
}

class _InventoryDetailScreenState
    extends ConsumerState<InventoryDetailScreen> {
  static const primaryColor = Color(0xFFEC6F2D);

  Color _scoreColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'a': return const Color(0xFF1E8449);
      case 'b': return const Color(0xFF58D68D);
      case 'c': return const Color(0xFFF4D03F);
      case 'd': return const Color(0xFFE67E22);
      case 'e': return const Color(0xFFE74C3C);
      default: return Colors.grey;
    }
  }

  Color _statusColor(InventoryItem item) {
    if (item.quantity == 0) return Colors.red;
    if (item.isLowStock) return Colors.orange;
    return const Color(0xFF27AE60);
  }

  String _statusLabel(InventoryItem item) {
    if (item.quantity == 0) return 'Out of stock';
    if (item.isLowStock) return 'Low stock';
    return 'In stock';
  }

  List<String> _getWarnings(InventoryItem item) {
    final warnings = <String>[];
    if (item.sugar != null && item.sugar! > 15) warnings.add('High Sugar');
    if (item.saturatedFat != null && item.saturatedFat! > 5)
      warnings.add('High Saturated Fat');
    if (item.salt != null && item.salt! > 1.5) warnings.add('High Salt');
    return warnings;
  }

  Color _expiryColor(InventoryItem item) {
    if (item.expirationDate == null) return Colors.grey;
    final daysLeft = item.expirationDate!.difference(DateTime.now()).inDays;
    if (daysLeft <= 3) return Colors.red;
    if (daysLeft <= 7) return Colors.orange;
    return const Color(0xFF27AE60);
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(inventoryProvider).valueOrNull?.firstWhere(
          (i) => i.id == widget.item.id,
          orElse: () => widget.item,
        ) ?? widget.item;
    final statusColor = _statusColor(item);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar avec image
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leadingWidth: 64,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: GestureDetector(
                    onTap: () => context.canPop() ? context.pop() : context.go('/inventory'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left,
                          color: primaryColor, size: 24),
                    ),
                  ),
                ),
                title: const Text('Product Details',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: item.imageUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder()),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.2),
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildPlaceholder(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom + marque
                      Text(item.name,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                      if (item.brand.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.brand,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                      ],
                      if (item.category.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_categoryIcon(item.category),
                                  size: 14, color: primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                _capitalize(item.category),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else
                        const SizedBox(height: 16),

                      // Stock status card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: statusColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.inventory_2_outlined,
                                  color: statusColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(_statusLabel(item),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor)),
                                  Text(
                                      '${item.quantity} ${item.unit} remaining',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey)),
                                ],
                              ),
                            ),
                            // Qty controls
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _PillButton(
                                    icon: Icons.remove,
                                    color: primaryColor,
                                    onTap: () => ref
                                        .read(inventoryProvider.notifier)
                                        .updateQuantity(item.id,
                                            item.quantity - 1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Text(
                                      item.quantity.toString(),
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: item.quantity == 0
                                              ? Colors.red
                                              : const Color(0xFF1A1A1A)),
                                    ),
                                  ),
                                  _PillButton(
                                    icon: Icons.add,
                                    color: primaryColor,
                                    onTap: () => ref
                                        .read(inventoryProvider.notifier)
                                        .updateQuantity(item.id,
                                            item.quantity + 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Infos inventaire (category, storage, expiry)
                      if (item.category.isNotEmpty ||
                          item.storageLocation.isNotEmpty ||
                          item.expirationDate != null ||
                          item.daysRemaining != null ||
                          item.dailyConsumption != null ||
                          item.notes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Storage Info',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A))),
                              const SizedBox(height: 12),
                              if (item.category.isNotEmpty)
                                _InfoRow(
                                    icon: Icons.category_outlined,
                                    label: 'Category',
                                    value: _capitalize(item.category)),
                              if (item.storageLocation.isNotEmpty)
                                _InfoRow(
                                    icon: Icons.kitchen_outlined,
                                    label: 'Location',
                                    value: _capitalize(
                                        item.storageLocation)),
                              if (item.expirationDate != null)
                                _InfoRow(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Expires',
                                    value:
                                        '${item.expirationDate!.day}/${item.expirationDate!.month}/${item.expirationDate!.year}',
                                    valueColor: _expiryColor(item)),
                              if (item.daysRemaining != null)
                                _InfoRow(
                                  icon: Icons.timer_outlined,
                                  label: 'Stock Duration',
                                  value: item.daysRemaining! <= 1
                                      ? 'Less than 1 day'
                                      : '~${item.daysRemaining!.toStringAsFixed(0)} days left',
                                  valueColor: item.daysRemaining! <= 3
                                      ? Colors.red
                                      : item.daysRemaining! <= 7
                                          ? Colors.orange
                                          : const Color(0xFF27AE60),
                                ),
                              if (item.dailyConsumption != null)
                                _InfoRow(
                                  icon: Icons.trending_down_outlined,
                                  label: 'Daily Usage',
                                  value: '${item.dailyConsumption!.toStringAsFixed(1)} ${item.unit}/day',
                                ),
                              if (item.notes.isNotEmpty)
                                _InfoRow(
                                    icon: Icons.notes_outlined,
                                    label: 'Notes',
                                    value: item.notes),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Nutriscore
                      if (item.nutriscore != null) ...[
                        _NutriscoreCard(
                            score: item.nutriscore!,
                            scoreColor: _scoreColor(item.nutriscore)),
                        const SizedBox(height: 16),
                      ],

                      // Warnings
                      if (_getWarnings(item).isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _getWarnings(item)
                              .map((w) => _WarningBadge(label: w))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Nutrition facts
                      _NutritionCard(item: item),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  // Delete
                  GestureDetector(
                    onTap: () async {
                      final confirmed = await AppDialogs.warning(
                        context,
                        title: 'Remove item',
                        message: 'Remove "${item.name}" from your inventory?',
                        confirmLabel: 'Remove',
                      );
                      if (confirmed == true && mounted) {
                        await ref
                            .read(inventoryProvider.notifier)
                            .deleteItem(item.id);
                        if (mounted) context.pop();
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ask AI
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'AI Assistant coming in Sprint 3!')),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.smart_toy_outlined,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Ask AI Assistant',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'fruits': return Icons.apple;
      case 'vegetables': return Icons.eco_outlined;
      case 'dairy': return Icons.water_drop_outlined;
      case 'meat': return Icons.set_meal_outlined;
      case 'snacks': return Icons.cookie_outlined;
      case 'beverages': return Icons.local_drink_outlined;
      case 'grains': return Icons.grain;
      default: return Icons.category_outlined;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: const Center(
          child: Icon(Icons.fastfood, size: 64, color: Colors.grey)),
    );
  }
}

// Widgets helpers
class _PillButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PillButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}

class _NutriscoreCard extends StatelessWidget {
  final String score;
  final Color scoreColor;

  const _NutriscoreCard(
      {required this.score, required this.scoreColor});

  String _scoreLabel(String s) {
    switch (s.toLowerCase()) {
      case 'a': return 'Excellent nutritional quality.';
      case 'b': return 'Good nutritional quality overall.';
      case 'c': return 'Average quality. Consume in moderation.';
      case 'd': return 'Poor quality. Limit consumption.';
      case 'e': return 'Bad quality. Avoid if possible.';
      default: return 'Nutritional quality unknown.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC6F2D), Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nutrition Score',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Row(
                children: ['a', 'b', 'c', 'd', 'e'].map((g) {
                  final isActive = g == score.toLowerCase();
                  return Container(
                    margin: const EdgeInsets.only(left: 6),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? scoreColor
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(g.toUpperCase(),
                          style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white38,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_scoreLabel(score),
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

class _WarningBadge extends StatelessWidget {
  final String label;
  const _WarningBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: Color(0xFFE67E22)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE67E22),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final InventoryItem item;
  const _NutritionCard({required this.item});

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nutrition Facts',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A))),
          const Text('per 100g',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          _NutritionRow(label: 'Calories',
              value: item.calories != null
                  ? '${item.calories!.toStringAsFixed(0)} kcal' : '—'),
          _NutritionRow(label: 'Fat',
              value: item.fat != null
                  ? '${item.fat!.toStringAsFixed(1)}g' : '—'),
          _NutritionRow(label: 'Saturated Fat',
              value: item.saturatedFat != null
                  ? '${item.saturatedFat!.toStringAsFixed(1)}g' : '—'),
          _NutritionRow(label: 'Carbohydrates',
              value: item.carbohydrates != null
                  ? '${item.carbohydrates!.toStringAsFixed(1)}g' : '—'),
          _NutritionRow(label: 'Sugar',
              value: item.sugar != null
                  ? '${item.sugar!.toStringAsFixed(1)}g' : '—'),
          _NutritionRow(label: 'Fiber',
              value: item.fiber != null
                  ? '${item.fiber!.toStringAsFixed(1)}g' : '—'),
          _NutritionRow(label: 'Protein',
              value: item.protein != null
                  ? '${item.protein!.toStringAsFixed(1)}g' : '—'),
          _NutritionRow(label: 'Salt',
              value: item.salt != null
                  ? '${item.salt!.toStringAsFixed(1)}g' : '—',
              isLast: true),
        ],
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _NutritionRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF555555))),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
      ],
    );
  }
}