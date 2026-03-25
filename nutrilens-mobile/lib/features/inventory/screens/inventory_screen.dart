import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_model.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

enum _SortOption { nameAZ, nameZA, qtyAsc, qtyDesc, status }

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  static const primaryColor = Color(0xFFEC6F2D);
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.nameAZ;
  static const _lowStockPreviewCount = 3;

  static const _sortLabels = {
    _SortOption.nameAZ: 'Name (A → Z)',
    _SortOption.nameZA: 'Name (Z → A)',
    _SortOption.qtyAsc: 'Quantity (ascending)',
    _SortOption.qtyDesc: 'Quantity (descending)',
    _SortOption.status: 'Status (out of stock first)',
  };

  static const _sortIcons = {
    _SortOption.nameAZ: Icons.sort_by_alpha,
    _SortOption.nameZA: Icons.sort_by_alpha,
    _SortOption.qtyAsc: Icons.arrow_upward_rounded,
    _SortOption.qtyDesc: Icons.arrow_downward_rounded,
    _SortOption.status: Icons.warning_amber_rounded,
  };

  List<InventoryItem> _sorted(List<InventoryItem> items) {
    final list = [...items];
    switch (_sortOption) {
      case _SortOption.nameAZ:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _SortOption.nameZA:
        list.sort((a, b) => b.name.compareTo(a.name));
      case _SortOption.qtyAsc:
        list.sort((a, b) => a.quantity.compareTo(b.quantity));
      case _SortOption.qtyDesc:
        list.sort((a, b) => b.quantity.compareTo(a.quantity));
      case _SortOption.status:
        list.sort((a, b) => a.quantity.compareTo(b.quantity));
    }
    return list;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sort by',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 12),
            ..._SortOption.values.map((opt) {
              final selected = _sortOption == opt;
              return GestureDetector(
                onTap: () {
                  setState(() => _sortOption = opt);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: selected
                        ? primaryColor.withOpacity(0.08)
                        : const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? primaryColor.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(children: [
                    Icon(_sortIcons[opt]!,
                        size: 18,
                        color: selected ? primaryColor : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_sortLabels[opt]!,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? primaryColor
                                  : const Color(0xFF1A1A1A))),
                    ),
                    if (selected)
                      Icon(Icons.check_circle_rounded,
                          color: primaryColor, size: 18),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showLowStockSheet(List<InventoryItem> lowStock) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Icon(Icons.warning_amber_rounded,
                    color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Low Stock — ${lowStock.length} items',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A)),
                ),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: lowStock.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = lowStock[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.inventory_2_outlined,
                              color: primaryColor,
                              size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A))),
                              Text(
                                  '${item.quantity} ${item.unit} left',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.quantity == 0
                                ? Colors.red
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.quantity == 0 ? 'Critical' : 'Low',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: inventoryState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: primaryColor)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.grey, size: 48),
              const SizedBox(height: 12),
              Text(e.toString(),
                  style: const TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () =>
                    ref.read(inventoryProvider.notifier).fetchInventory(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (items) {
          final filtered = _sorted(items
              .where((i) => i.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
              .toList());
          final lowStock = items.where((i) => i.isLowStock).toList();

          return Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                    24, MediaQuery.of(context).padding.top + 16, 24, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
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
                          const Text('Food Inventory',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A))),
                        ]),
                        Row(children: [
                          GestureDetector(
                            onTap: _showSortSheet,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _sortOption != _SortOption.nameAZ
                                    ? primaryColor.withOpacity(0.12)
                                    : const Color(0xFFF0F0F0),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.sort_rounded,
                                  color: _sortOption != _SortOption.nameAZ
                                      ? primaryColor
                                      : Colors.grey,
                                  size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.push('/scanner'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEC6F2D),
                                    Color(0xFFFF9A5C)
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3)),
                                ],
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        hintStyle: const TextStyle(
                            color: Colors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.grey, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFEEEEEE)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFEEEEEE)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: primaryColor, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Low stock alert
                      if (lowStock.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.05),
                            border: Border(
                              bottom: BorderSide(
                                  color: primaryColor.withOpacity(0.1)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: primaryColor, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Low Stock (${lowStock.length} items)',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor),
                                    ),
                                  ]),
                                  if (lowStock.length > _lowStockPreviewCount)
                                    GestureDetector(
                                      onTap: () =>
                                          _showLowStockSheet(lowStock),
                                      child: Row(children: [
                                        Text(
                                          'View all',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: primaryColor),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(Icons.chevron_right,
                                            color: primaryColor, size: 16),
                                      ]),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Column(
                                  children: lowStock
                                      .take(_lowStockPreviewCount)
                                      .toList()
                                      .map((item) => Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            padding:
                                                const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: const Color(
                                                      0xFFEEEEEE)),
                                            ),
                                            child: Row(children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: primaryColor
                                                      .withOpacity(0.08),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                    Icons
                                                        .inventory_2_outlined,
                                                    color: primaryColor,
                                                    size: 16),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                  child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.name,
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Color(
                                                              0xFF1A1A1A))),
                                                  Text(
                                                      '${item.quantity} ${item.unit} left',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Colors.grey)),
                                                ],
                                              )),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: item.quantity == 0
                                                      ? Colors.red
                                                      : Colors.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20),
                                                ),
                                                child: Text(
                                                  item.quantity == 0
                                                      ? 'Critical'
                                                      : 'Low',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ]),
                                          ))
                                      .toList(),
                                ),
                            ],
                          ),
                        ),

                      // All items
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Text(
                          'ALL ITEMS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                              letterSpacing: 0.08),
                        ),
                      ),

                      if (filtered.isEmpty)
                        _EmptyState(primaryColor: primaryColor)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _InventoryCard(
                            item: filtered[i],
                            primaryColor: primaryColor,
                            onIncrement: () => ref
                                .read(inventoryProvider.notifier)
                                .updateQuantity(filtered[i].id,
                                    filtered[i].quantity + 1),
                            onDecrement: () => ref
                                .read(inventoryProvider.notifier)
                                .updateQuantity(filtered[i].id,
                                    filtered[i].quantity - 1),
                            onDelete: () => ref
                                .read(inventoryProvider.notifier)
                                .deleteItem(filtered[i].id),
                          ),
                        ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Stats footer
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                        value: items.length.toString(),
                        label: 'Total Items',
                        color: primaryColor),
                    Container(
                        width: 1, height: 32, color: Colors.grey[300]),
                    _StatItem(
                        value: lowStock.length.toString(),
                        label: 'Low Stock',
                        color: Colors.orange),
                    Container(
                        width: 1, height: 32, color: Colors.grey[300]),
                    _StatItem(
                        value: items
                            .where((i) => i.quantity == 0)
                            .length
                            .toString(),
                        label: 'Critical',
                        color: Colors.red),
                  ],
                ),
              ),
            ],
          );
        },
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove item',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${item.name}" from your inventory?',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actionsPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEEEEEE)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Remove',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }

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

  Color _statusColor() {
    if (item.quantity == 0) return Colors.red;
    if (item.isLowStock) return Colors.orange;
    return const Color(0xFF27AE60);
  }

  String _statusLabel() {
    if (item.quantity == 0) return 'Out of stock';
    if (item.isLowStock) return 'Low stock';
    return 'In stock';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final progress = (item.quantity /
            (item.lowStockThreshold * 3).clamp(1, 100).toDouble())
        .clamp(0.0, 1.0);

    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Remove item',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            content: Text(
              'Remove "${item.name}" from your inventory?',
              style:
                  const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFEEEEEE)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('Remove',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ],
          ),
        );
        return confirmed == true;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(item.quantity == 0 || item.isLowStock ? 0.08 : 0.0),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product image with nutriscore badge
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: item.imageUrl != null
                                      ? Image.network(
                                          item.imageUrl!,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildPlaceholder(),
                                        )
                                      : _buildPlaceholder(),
                                ),
                                if (item.nutriscore != null)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _scoreColor(item.nutriscore),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(14),
                                          bottomRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          item.nutriscore!.toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // Name, brand, status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A1A),
                                        height: 1.2),
                                  ),
                                  if (item.brand.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      item.brand,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9E9E9E)),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _statusLabel(),
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: statusColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item.calories != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '${item.calories!.toStringAsFixed(0)} kcal',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF9E9E9E)),
                                      ),
                                    ],
                                  ]),
                                ],
                              ),
                            ),

                            // Delete button
                            GestureDetector(
                              onTap: () => _confirmDelete(context),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 16,
                                    color: Colors.red),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Bottom: progress + qty pill
                        Row(
                          children: [
                            // Progress bar
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: const Color(0xFFEEEEEE),
                                  valueColor:
                                      AlwaysStoppedAnimation(statusColor),
                                  minHeight: 6,
                                ),
                              ),
                            ),

                            const SizedBox(width: 14),

                            // Qty pill: [−] N [+]
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
                                      onTap: onDecrement,
                                      color: primaryColor),
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
                                      onTap: onIncrement,
                                      color: primaryColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.fastfood_rounded,
          color: Color(0xFFCCCCCC), size: 26),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _PillButton(
      {required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color primaryColor;
  const _EmptyState({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined,
                  color: primaryColor, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Your inventory is empty',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            const Text('Scan products to add them here',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}