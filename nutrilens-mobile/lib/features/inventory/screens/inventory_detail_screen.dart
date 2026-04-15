import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../scanner/models/product_model.dart';
import '../../scanner/models/analysis_model.dart';
import '../../scanner/providers/analysis_provider.dart';
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
  static const _expandedHeight = 220.0;

  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      ref.read(inventoryAnalysisProvider.notifier).analyze(_toProductModel(widget.item));
    });
  }

  void _onScroll() {
    final collapsed =
        _scrollController.offset > _expandedHeight - kToolbarHeight - 16;
    if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  ProductModel _toProductModel(InventoryItem item) => ProductModel(
        barcode: item.barcode,
        name: item.name,
        brand: item.brand.isNotEmpty ? item.brand : null,
        imageUrl: item.imageUrl,
        nutriscore: item.nutriscore,
        allergens: const [],
        ingredients: const [],
        nutrition: NutritionFacts(
          calories: item.calories,
          fat: item.fat,
          saturatedFat: item.saturatedFat,
          carbohydrates: item.carbohydrates,
          sugar: item.sugar,
          fiber: item.fiber,
          protein: item.protein,
          salt: item.salt,
        ),
      );

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
            ) ??
        widget.item;

    final analysisState = ref.watch(inventoryAnalysisProvider);
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final statusColor = _statusColor(item);
    final iconColor = (!_isCollapsed && hasImage) ? Colors.white : primaryColor;
    final iconBg = (!_isCollapsed && hasImage)
        ? Colors.black.withOpacity(0.25)
        : primaryColor.withOpacity(0.08);
    final titleColor =
        (!_isCollapsed && hasImage) ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: _expandedHeight,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leadingWidth: 64,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: GestureDetector(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/inventory'),
                    child: Container(
                      decoration:
                          BoxDecoration(color: iconBg, shape: BoxShape.circle),
                      child: Icon(Icons.chevron_left,
                          color: iconColor, size: 24),
                    ),
                  ),
                ),
                title: Text('Product Details',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: titleColor)),
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: item.imageUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(item.imageUrl!,
                                fit: BoxFit.cover,
                                frameBuilder: (_, child, frame,
                                    wasSynchronouslyLoaded) {
                                  if (wasSynchronouslyLoaded || frame != null) {
                                    return child;
                                  }
                                  return Container(
                                    color: Colors.black,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFFEC6F2D)),
                                    ),
                                  );
                                },
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
                      // Name & brand
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
                        const SizedBox(height: 8),
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
                              Text(_capitalize(item.category),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Stock status card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: statusColor.withOpacity(0.2)),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_statusLabel(item),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor)),
                                  Text(
                                      '${item.quantity} ${item.unit} remaining',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
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
                                        .updateQuantity(
                                            item.id, item.quantity - 1),
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
                                        .updateQuantity(
                                            item.id, item.quantity + 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Storage info
                      if (item.storageLocation.isNotEmpty ||
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
                              if (item.storageLocation.isNotEmpty)
                                _InfoRow(
                                    icon: Icons.kitchen_outlined,
                                    label: 'Location',
                                    value: _capitalize(item.storageLocation)),
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
                                  value:
                                      '${item.dailyConsumption!.toStringAsFixed(1)} ${item.unit}/day',
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
                        _NutriscoreCard(score: item.nutriscore!),
                        const SizedBox(height: 16),
                      ],

                      // NutriLens AI Analysis
                      analysisState.when(
                        loading: () => _AnalysisLoadingCard(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (result) => result == null
                            ? const SizedBox.shrink()
                            : Column(
                                children: [
                                  _NutriLensScoreCard(result: result),
                                  const SizedBox(height: 16),
                                  if (result.warnings.isNotEmpty) ...[
                                    _WarningsCard(warnings: result.warnings),
                                    const SizedBox(height: 16),
                                  ],
                                  if (result.recommendations.isNotEmpty) ...[
                                    _RecommendationsCard(
                                        recommendations:
                                            result.recommendations),
                                    const SizedBox(height: 16),
                                  ],
                                ],
                              ),
                      ),

                      // Key Nutrition Facts
                      analysisState.when(
                        loading: () => _KeyNutritionCard(
                            nutrition: _toProductModel(item).nutrition,
                            warnings: const []),
                        error: (_, __) => _KeyNutritionCard(
                            nutrition: _toProductModel(item).nutrition,
                            warnings: const []),
                        data: (result) => _KeyNutritionCard(
                            nutrition: _toProductModel(item).nutrition,
                            warnings: result?.warnings ?? const []),
                      ),
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
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final confirmed = await AppDialogs.warning(
                        context,
                        title: 'Remove item',
                        message:
                            'Remove "${item.name}" from your inventory?',
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
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('AI Assistant coming in Sprint 3!')),
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

  Widget _buildPlaceholder() => Container(
        color: const Color(0xFFF0F0F0),
        child: const Center(
            child: Icon(Icons.fastfood, size: 64, color: Colors.grey)),
      );

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'fruits':
        return Icons.apple;
      case 'vegetables':
        return Icons.eco_outlined;
      case 'dairy':
        return Icons.water_drop_outlined;
      case 'meat':
        return Icons.set_meal_outlined;
      case 'snacks':
        return Icons.cookie_outlined;
      case 'beverages':
        return Icons.local_drink_outlined;
      case 'grains':
        return Icons.grain;
      default:
        return Icons.category_outlined;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Pill Button ───────────────────────────────────────────────────────────────

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

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF1A1A1A))),
          ),
        ],
      ),
    );
  }
}

// ── Nutriscore Card ───────────────────────────────────────────────────────────

class _NutriscoreCard extends StatelessWidget {
  final String score;
  const _NutriscoreCard({required this.score});

  Color _scoreColor(String s) {
    switch (s.toLowerCase()) {
      case 'a': return const Color(0xFF1E8449);
      case 'b': return const Color(0xFF58D68D);
      case 'c': return const Color(0xFFF4D03F);
      case 'd': return const Color(0xFFE67E22);
      case 'e': return const Color(0xFFE74C3C);
      default: return Colors.grey;
    }
  }

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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEC6F2D), Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(
                child: Text('Nutri-Score',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              ...['a', 'b', 'c', 'd', 'e'].map((g) {
                final isActive = g == score.toLowerCase();
                return Container(
                  margin: const EdgeInsets.only(left: 5),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? _scoreColor(g)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(g.toUpperCase(),
                        style: TextStyle(
                            color: isActive ? Colors.white : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                );
              }),
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

// ── NutriLens Score Card ──────────────────────────────────────────────────────

Color _nlScoreColor(int score) {
  if (score >= 85) return const Color(0xFF27AE60);
  if (score >= 70) return const Color(0xFF2ECC71);
  if (score >= 55) return const Color(0xFFF4D03F);
  if (score >= 40) return const Color(0xFFE67E22);
  if (score >= 20) return const Color(0xFFE74C3C);
  return const Color(0xFFB71C1C);
}

String _nlScoreLabel(int score) {
  if (score >= 85) return 'Great match for your profile';
  if (score >= 70) return 'Good — minor concerns';
  if (score >= 55) return 'Acceptable — check details';
  if (score >= 40) return 'Caution — check warnings';
  if (score >= 20) return 'Not recommended for you';
  return 'Avoid — conflicts with your profile';
}

class _NutriLensScoreCard extends StatelessWidget {
  final AnalysisResult result;
  const _NutriLensScoreCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = _nlScoreColor(result.score);
    final label = _nlScoreLabel(result.score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(
                  painter: _ArcGaugePainter(score: result.score, color: color),
                  child: Center(
                    child: Text('${result.score}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: color)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NutriLens Score',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    if (result.hasDanger) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5E5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('⚠ Health alert detected',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFE74C3C),
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (result.reasons.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            ...result.reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(r,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF555555),
                                height: 1.5)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final int score;
  final Color color;
  const _ArcGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const startAngle = math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      Paint()
        ..color = const Color(0xFFEEEEEE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    final filled = sweepTotal * (score / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      filled,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.score != score || old.color != color;
}

// ── Analysis Loading Card ─────────────────────────────────────────────────────

class _AnalysisLoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFFEC6F2D)),
          ),
          SizedBox(width: 14),
          Flexible(
            child: Text('Analyzing against your health profile...',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// ── Warnings Card ─────────────────────────────────────────────────────────────

class _WarningsCard extends StatelessWidget {
  final List<AnalysisWarning> warnings;
  const _WarningsCard({required this.warnings});

  Color _severityColor(String severity) {
    switch (severity) {
      case 'danger': return const Color(0xFFE74C3C);
      case 'warning': return const Color(0xFFE67E22);
      default: return const Color(0xFF2D9CDB);
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'danger': return Icons.dangerous_rounded;
      case 'warning': return Icons.warning_amber_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

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
          const Row(children: [
            Icon(Icons.shield_outlined, color: Color(0xFFEC6F2D), size: 18),
            SizedBox(width: 8),
            Text('Health Warnings',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
          ]),
          const SizedBox(height: 14),
          ...warnings.map((w) {
            final color = _severityColor(w.severity);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(_severityIcon(w.severity), color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.label,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color)),
                        if (w.detail.isNotEmpty)
                          Text(w.detail,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Recommendations Card ──────────────────────────────────────────────────────

class _RecommendationsCard extends StatelessWidget {
  final List<String> recommendations;
  const _RecommendationsCard({required this.recommendations});

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
          const Row(children: [
            Icon(Icons.lightbulb_outline_rounded,
                color: Color(0xFFEC6F2D), size: 18),
            SizedBox(width: 8),
            Text('Recommendations',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
          ]),
          const SizedBox(height: 14),
          ...recommendations.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ',
                        style: TextStyle(
                            color: Color(0xFFEC6F2D),
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Expanded(
                      child: Text(r,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF3D3D3D),
                              height: 1.5)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Key Nutrition Card ────────────────────────────────────────────────────────

class _KeyNutritionCard extends StatelessWidget {
  final NutritionFacts nutrition;
  final List<AnalysisWarning> warnings;
  const _KeyNutritionCard(
      {required this.nutrition, required this.warnings});

  Color? _warningColor(String nutrientKey) {
    final codes = {
      'sugar': ['high_sugar', 'soft_sugar'],
      'salt': ['high_salt', 'soft_salt'],
      'fat': ['high_sat_fat'],
    };
    final relevant = codes[nutrientKey] ?? [];
    for (final w in warnings) {
      if (relevant.contains(w.code)) {
        return w.severity == 'danger'
            ? const Color(0xFFE74C3C)
            : w.severity == 'warning'
                ? const Color(0xFFE67E22)
                : const Color(0xFF2D9CDB);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Key Nutrition Facts',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 16),
          _NutritionRow(
              icon: Icons.local_fire_department,
              label: 'Calories',
              value: nutrition.calories != null
                  ? '${nutrition.calories!.toStringAsFixed(0)} kcal'
                  : '—',
              sub: 'per 100g',
              alertColor: null),
          const SizedBox(height: 12),
          _NutritionRow(
              icon: Icons.water_drop_outlined,
              label: 'Sugar',
              value: nutrition.sugar != null
                  ? '${nutrition.sugar!.toStringAsFixed(1)}g'
                  : '—',
              sub: 'per 100g',
              alertColor: _warningColor('sugar')),
          const SizedBox(height: 12),
          _NutritionRow(
              icon: Icons.circle_outlined,
              label: 'Fat',
              value: nutrition.fat != null
                  ? '${nutrition.fat!.toStringAsFixed(1)}g'
                  : '—',
              sub: 'per 100g',
              alertColor: _warningColor('fat')),
          const SizedBox(height: 12),
          _NutritionRow(
              icon: Icons.water_outlined,
              label: 'Salt',
              value: nutrition.salt != null
                  ? '${nutrition.salt!.toStringAsFixed(2)}g'
                  : '—',
              sub: 'per 100g',
              alertColor: _warningColor('salt')),
          const SizedBox(height: 12),
          _NutritionRow(
              icon: Icons.fitness_center,
              label: 'Protein',
              value: nutrition.protein != null
                  ? '${nutrition.protein!.toStringAsFixed(1)}g'
                  : '—',
              sub: 'per 100g',
              alertColor: null),
          const SizedBox(height: 12),
          _NutritionRow(
              icon: Icons.grain,
              label: 'Carbohydrates',
              value: nutrition.carbohydrates != null
                  ? '${nutrition.carbohydrates!.toStringAsFixed(1)}g'
                  : '—',
              sub: 'per 100g',
              alertColor: null),
          const SizedBox(height: 12),
          _NutritionRow(
              icon: Icons.spa_outlined,
              label: 'Fiber',
              value: nutrition.fiber != null
                  ? '${nutrition.fiber!.toStringAsFixed(1)}g'
                  : '—',
              sub: 'per 100g',
              alertColor: null),
        ],
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color? alertColor;
  static const primaryColor = Color(0xFFEC6F2D);

  const _NutritionRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.sub,
      required this.alertColor});

  @override
  Widget build(BuildContext context) {
    final iconFg = alertColor ?? primaryColor;
    final iconBg = iconFg.withOpacity(0.08);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconFg, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: alertColor != null
                          ? alertColor!
                          : const Color(0xFF1A1A1A))),
              Text(sub,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: alertColor ?? const Color(0xFF1A1A1A))),
            ),
            if (alertColor != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.warning_amber_rounded,
                  size: 14, color: alertColor),
            ],
          ],
        ),
      ],
    );
  }
}
