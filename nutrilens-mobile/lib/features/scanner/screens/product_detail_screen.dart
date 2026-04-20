import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../models/analysis_model.dart';
import '../providers/analysis_provider.dart';
import '../../scanner/providers/scan_history_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  static const primaryColor = Color(0xFFEC6F2D);
  static const _expandedHeight = 220.0;

  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  ProductModel get product => widget.product;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(scanHistoryProvider.notifier).addScan(widget.product);
      // Analysis was pre-triggered in scanner screen during navigation animation.
      // Only trigger here if state was reset (e.g. direct navigation from history).
      final current = ref.read(analysisProvider);
      if (current is AsyncData && current.value == null) {
        ref.read(analysisProvider.notifier).analyze(widget.product);
      }
    });
    _scrollController.addListener(_onScroll);
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

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    final iconColor =
        (!_isCollapsed && hasImage) ? Colors.white : primaryColor;
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
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                          color: iconBg, shape: BoxShape.circle),
                      child: Icon(Icons.chevron_left,
                          color: iconColor, size: 24),
                    ),
                  ),
                ),
                title: Text('Product Analysis',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: titleColor)),
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: product.imageUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(product.imageUrl!,
                                fit: BoxFit.cover,
                                frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
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
                      Text(product.name,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                      if (product.brand != null) ...[
                        const SizedBox(height: 4),
                        Text(product.brand!,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                      ],
                      const SizedBox(height: 16),

                      // Nutriscore
                      if (product.nutriscore != null) ...[
                        _NutriscoreCard(score: product.nutriscore!),
                        const SizedBox(height: 16),
                      ],

                      // NutriLens Analysis (NL-23/24/25/26)
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

                      // Key nutrition facts
                      analysisState.when(
                        loading: () => _KeyNutritionCard(nutrition: product.nutrition, warnings: const []),
                        error: (_, __) => _KeyNutritionCard(nutrition: product.nutrition, warnings: const []),
                        data: (result) => _KeyNutritionCard(
                            nutrition: product.nutrition,
                            warnings: result?.warnings ?? const []),
                      ),
                      const SizedBox(height: 16),

                      // Allergens
                      if (product.allergens.isNotEmpty) ...[
                        _AllergenCard(allergens: product.allergens),
                        const SizedBox(height: 16),
                      ],

                      // Ingredients (highlighted)
                      if (product.ingredients.isNotEmpty)
                        analysisState.when(
                          loading: () => _IngredientsCard(
                              ingredients: product.ingredients,
                              highlighted: const []),
                          error: (_, __) => _IngredientsCard(
                              ingredients: product.ingredients,
                              highlighted: const []),
                          data: (result) => _IngredientsCard(
                              ingredients: product.ingredients,
                              highlighted:
                                  result?.highlightedIngredients ?? const []),
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
                border:
                    Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('AI Assistant coming in Sprint 3!')),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.smart_toy_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Ask AI Assistant',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () =>
                          context.push('/inventory/add', extra: widget.product),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFEEEEEE), width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart,
                              size: 18, color: Color(0xFF1A1A1A)),
                          SizedBox(width: 8),
                          Text('Add to Inventory',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A))),
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
        child:
            const Center(child: Icon(Icons.fastfood, size: 64, color: Colors.grey)),
      );
}

// ── NutriLens Score Card ──────────────────────────────────────────────────────

Color _scoreColor(int score) {
  if (score >= 85) return const Color(0xFF27AE60);
  if (score >= 70) return const Color(0xFF2ECC71);
  if (score >= 55) return const Color(0xFFF4D03F);
  if (score >= 40) return const Color(0xFFE67E22);
  if (score >= 20) return const Color(0xFFE74C3C);
  return const Color(0xFFB71C1C);
}

String _scoreLabel(int score) {
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
    final color = _scoreColor(result.score);
    final label = _scoreLabel(result.score);

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
              // Arc gauge
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
          // Reasons
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
                          color: color,
                          shape: BoxShape.circle,
                        ),
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

    // Track
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

    // Fill
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

// ── Warnings Card (NL-25) ─────────────────────────────────────────────────────

class _WarningsCard extends StatelessWidget {
  final List<AnalysisWarning> warnings;
  const _WarningsCard({required this.warnings});

  Color _severityColor(String severity) {
    switch (severity) {
      case 'danger': return const Color(0xFFE74C3C);
      case 'warning': return const Color(0xFFE67E22);
      case 'info': return const Color(0xFF2D9CDB);
      default: return const Color(0xFF2D9CDB);
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'danger': return Icons.dangerous_rounded;
      case 'warning': return Icons.warning_amber_rounded;
      case 'info': return Icons.info_outline_rounded;
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
                    child: Icon(_severityIcon(w.severity),
                        color: color, size: 16),
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

// ── Recommendations Card (NL-26) ──────────────────────────────────────────────

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

// ── Analysis Loading Card ─────────────────────────────────────────────────────

class _AnalysisLoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
                    softWrap: true,
                    overflow: TextOverflow.visible,
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

// ── Key Nutrition Card ────────────────────────────────────────────────────────

class _KeyNutritionCard extends StatelessWidget {
  final NutritionFacts nutrition;
  final List<AnalysisWarning> warnings;
  const _KeyNutritionCard(
      {required this.nutrition, required this.warnings});

  /// Returns the alert color if a warning matches this nutrient, else null.
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
          decoration:
              BoxDecoration(color: iconBg, shape: BoxShape.circle),
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
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
              Icon(Icons.warning_amber_rounded, size: 14, color: alertColor),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Allergen Card ─────────────────────────────────────────────────────────────

class _AllergenCard extends StatelessWidget {
  final List<String> allergens;
  const _AllergenCard({required this.allergens});
  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            const Text('Allergens',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primaryColor)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergens
                .map((a) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(a,
                          style: const TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontWeight: FontWeight.w500)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Highlighted Ingredients Card (NL-24) ──────────────────────────────────────

class _IngredientsCard extends StatelessWidget {
  final List<String> ingredients;
  final List<String> highlighted;
  const _IngredientsCard(
      {required this.ingredients, required this.highlighted});

  bool _isHighlighted(String ingredient) {
    final lower = ingredient.toLowerCase();
    return highlighted.any((h) => lower.contains(h.toLowerCase()));
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ingredients',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A))),
              if (highlighted.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${highlighted.length} flagged',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE67E22),
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ingredients.map((ing) {
              final flag = _isHighlighted(ing);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: flag
                      ? const Color(0xFFFFF3CD)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                  border: flag
                      ? Border.all(
                          color: const Color(0xFFE67E22).withOpacity(0.4))
                      : null,
                ),
                child: Text(ing,
                    style: TextStyle(
                        fontSize: 12,
                        color: flag
                            ? const Color(0xFFE67E22)
                            : const Color(0xFF555555),
                        fontWeight: flag
                            ? FontWeight.w600
                            : FontWeight.w400)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
