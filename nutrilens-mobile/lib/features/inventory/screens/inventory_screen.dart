import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_model.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryState = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Food Inventory',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                      inventoryState.when(
                        data: (items) => Text('${items.length} items',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                        loading: () => const Text('Loading...',
                            style:
                                TextStyle(fontSize: 13, color: Colors.grey)),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () =>
                        ref.read(inventoryProvider.notifier).fetchInventory(),
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Low stock warning
            inventoryState.when(
                data: (items) {
                    final lowStock = items.where((i) => i.isLowStock).toList();
                    if (lowStock.isEmpty) return const SizedBox();
                    return Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                        children: [
                        Icon(Icons.warning_amber_rounded,
                            color: primaryColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                            '${lowStock.length} item${lowStock.length > 1 ? 's' : ''} running low on stock',
                            style: TextStyle(
                                fontSize: 13,
                                color: primaryColor,
                                fontWeight: FontWeight.w500),
                            ),
                        ),
                        ],
                    ),
                    );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
            ),

            // List
            Expanded(
              child: inventoryState.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: primaryColor)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.grey, size: 48),
                      const SizedBox(height: 12),
                      Text(e.toString(),
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref
                            .read(inventoryProvider.notifier)
                            .fetchInventory(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (items) => items.isEmpty
                    ? _EmptyState(primaryColor: primaryColor)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _InventoryCard(
                          item: items[i],
                          primaryColor: primaryColor,
                          onIncrement: () => ref
                              .read(inventoryProvider.notifier)
                              .updateQuantity(
                                  items[i].id, items[i].quantity + 1),
                          onDecrement: () => ref
                              .read(inventoryProvider.notifier)
                              .updateQuantity(
                                  items[i].id, items[i].quantity - 1),
                          onDelete: () => ref
                              .read(inventoryProvider.notifier)
                              .deleteItem(items[i].id),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final Color primaryColor;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  const _InventoryCard({
    required this.item,
    required this.primaryColor,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

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

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 24),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: item.isLowStock
              ? Border.all(color: primaryColor.withOpacity(0.3))
              : Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imageUrl != null
                  ? Image.network(item.imageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildImagePlaceholder())
                  : _buildImagePlaceholder(),
            ),
            const SizedBox(width: 12),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A))),
                      ),
                      if (item.nutriscore != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _scoreColor(item.nutriscore),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              item.nutriscore!.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.brand.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.brand,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                  if (item.calories != null) ...[
                    const SizedBox(height: 4),
                    Text(
                        '${item.calories!.toStringAsFixed(0)} kcal / 100g',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                  if (item.isLowStock) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 12, color: primaryColor),
                      const SizedBox(width: 4),
                      Text('Low stock',
                          style: TextStyle(
                              fontSize: 11,
                              color: primaryColor,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Quantity controls
            Row(
              children: [
                _QtyButton(
                    icon: Icons.remove,
                    onTap: onDecrement,
                    color: primaryColor),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    item.quantity.toString(),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A)),
                  ),
                ),
                _QtyButton(
                    icon: Icons.add,
                    onTap: onIncrement,
                    color: primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 24),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _QtyButton(
      {required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color primaryColor;
  const _EmptyState({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined,
                color: primaryColor, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Your inventory is empty',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          const Text('Scan products to add them here',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}