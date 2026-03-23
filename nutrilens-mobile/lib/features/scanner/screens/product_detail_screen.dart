import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
                // App Bar
                SliverAppBar(
                    expandedHeight: 220,
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
                            color: primaryColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                            ),
                            child: const Icon(
                            Icons.chevron_left,
                            color: primaryColor,
                            size: 24,
                            ),
                        ),
                        ),
                    ),

                    title: const Text(
                        'Product Analysis',
                        style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        ),
                    ),
                    centerTitle: true,

                    flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.parallax,
                        background: product.imageUrl != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                Image.network(
                                    product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                ),

                                // 👇 petit overlay pour lisibilité (effet premium)
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
                      // Product name & brand
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

                      // Nutriscore card
                      if (product.nutriscore != null) ...[
                        _NutriscoreCard(score: product.nutriscore!),
                        const SizedBox(height: 16),
                      ],

                      // Warning badges
                      if (_getWarnings().isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _getWarnings()
                              .map((w) => _WarningBadge(label: w))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Key nutrition facts
                      _KeyNutritionCard(nutrition: product.nutrition),
                      const SizedBox(height: 16),

                      // Allergens
                      if (product.allergens.isNotEmpty) ...[
                        _AllergenCard(allergens: product.allergens),
                        const SizedBox(height: 16),
                      ],

                      // AI Health Insights
                      _AIInsightsCard(
                          nutrition: product.nutrition,
                          allergens: product.allergens,
                          nutriscore: product.nutriscore),
                      const SizedBox(height: 16),

                      // Ingredients
                      if (product.ingredients.isNotEmpty) ...[
                        _IngredientsCard(
                            ingredients: product.ingredients),
                      ],
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
                    top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ask AI button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                              content: Text('AI Assistant coming in Sprint 3!'))),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Add to inventory button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Added to inventory!'),
                              backgroundColor: Colors.green),
                        );
                        Navigator.pop(context);
                      },
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

  List<String> _getWarnings() {
    final warnings = <String>[];
    final n = product.nutrition;
    if (n.sugar != null && n.sugar! > 15) warnings.add('High Sugar');
    if (n.saturatedFat != null && n.saturatedFat! > 5)
      warnings.add('High Saturated Fat');
    if (n.salt != null && n.salt! > 1.5) warnings.add('High Salt');
    if (product.allergens.isNotEmpty) warnings.add('Contains Allergens');
    return warnings;
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: const Center(
          child: Icon(Icons.fastfood, size: 64, color: Colors.grey)),
    );
  }
}

class _NutriscoreCard extends StatelessWidget {
  final String score;
  const _NutriscoreCard({required this.score});

  static const primaryColor = Color(0xFFEC6F2D);

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
      case 'a': return 'Excellent nutritional quality. Good source of fiber and protein.';
      case 'b': return 'Good nutritional quality overall.';
      case 'c': return 'Average nutritional quality. Consume in moderation.';
      case 'd': return 'Poor nutritional quality. Limit consumption.';
      case 'e': return 'Bad nutritional quality. Avoid if possible.';
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nutrition Score',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Row(
                children: ['a', 'b', 'c', 'd', 'e'].map((g) {
                  final isActive =
                      g == score.toLowerCase();
                  return Container(
                    margin: const EdgeInsets.only(left: 6),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? _scoreColor(g)
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
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
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

class _KeyNutritionCard extends StatelessWidget {
  final NutritionFacts nutrition;
  const _KeyNutritionCard({required this.nutrition});

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
              sub: 'per 100g'),
          const SizedBox(height: 12),
          _NutritionRow(
              icon: Icons.water_drop_outlined,
              label: 'Sugar',
              value: nutrition.sugar != null
                  ? '${nutrition.sugar!.toStringAsFixed(1)}g'
                  : '—',
              sub: 'per 100g'),
          const SizedBox(height: 12),
          _NutritionRow(
              icon: Icons.circle_outlined,
              label: 'Fat',
              value: nutrition.fat != null
                  ? '${nutrition.fat!.toStringAsFixed(1)}g'
                  : '—',
              sub: 'per 100g'),
          const SizedBox(height: 12),
          _NutritionRow(
              icon: Icons.fitness_center,
              label: 'Protein',
              value: nutrition.protein != null
                  ? '${nutrition.protein!.toStringAsFixed(1)}g'
                  : '—',
              sub: 'per 100g'),
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

  const _NutritionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A))),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A))),
      ],
    );
  }
}

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
            Icon(Icons.warning_amber_rounded,
                color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text('Allergens',
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
                          style: TextStyle(
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

class _AIInsightsCard extends StatelessWidget {
  final NutritionFacts nutrition;
  final List<String> allergens;
  final String? nutriscore;

  const _AIInsightsCard({
    required this.nutrition,
    required this.allergens,
    this.nutriscore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.smart_toy_outlined,
                color: Color(0xFF9B51E0), size: 18),
            SizedBox(width: 8),
            Text('AI Health Insights',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
          ]),
          const SizedBox(height: 14),
          if (nutriscore != null &&
              (nutriscore == 'a' || nutriscore == 'b'))
            _InsightRow(
              emoji: '✓',
              color: const Color(0xFF1E8449),
              label: 'Good for:',
              text: 'Quick energy boost, balanced nutritional profile.',
            ),
          if (nutrition.sugar != null && nutrition.sugar! > 15)
            _InsightRow(
              emoji: '⚠',
              color: const Color(0xFFE67E22),
              label: 'Watch out:',
              text:
                  'Contains added sugars. Best consumed in moderation if monitoring sugar intake.',
            ),
          if (allergens.isNotEmpty)
            _InsightRow(
              emoji: '⚠',
              color: const Color(0xFFEC6F2D),
              label: 'Allergens:',
              text:
                  'Contains ${allergens.take(3).join(', ')}. Check with your health profile.',
            ),
          _InsightRow(
            emoji: '💡',
            color: const Color(0xFF2D9CDB),
            label: 'Tip:',
            text:
                'Pairs well with a protein source for a more balanced meal.',
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String emoji;
  final Color color;
  final String label;
  final String text;

  const _InsightRow({
    required this.emoji,
    required this.color,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF555555), height: 1.5),
          children: [
            TextSpan(text: '$emoji '),
            TextSpan(
                text: '$label ',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: color)),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

class _IngredientsCard extends StatelessWidget {
  final List<String> ingredients;
  const _IngredientsCard({required this.ingredients});

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
          const Text('Ingredients',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 10),
          Text(ingredients.join(', '),
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                  height: 1.6)),
        ],
      ),
    );
  }
}