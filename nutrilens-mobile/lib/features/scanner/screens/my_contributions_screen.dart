import 'package:flutter/material.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../models/user_product_model.dart';
import '../services/user_product_service.dart';
import 'add_user_product_screen.dart';

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  static const primaryColor = Color(0xFFEC6F2D);

  final _service = UserProductService();
  late Future<List<UserProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAll();
  }

  void _reload() {
    final f = _service.getAll();
    setState(() { _future = f; });
  }

  void _showOptions(BuildContext context, UserProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: Colors.black54, size: 18),
              ),
              title: const Text('Edit',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Modify product info or nutrition'),
              onTap: () async {
                Navigator.pop(context);
                final oldImageUrl = product.imageUrl;
                final updated = await Navigator.push<UserProductModel>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddUserProductScreen(product: product),
                  ),
                );
                if (updated != null) {
                  // Evict old image from every cache layer if the URL changed
                  if (oldImageUrl != null && oldImageUrl != updated.imageUrl) {
                    NetworkImage(oldImageUrl).evict();
                    imageCache.evict(NetworkImage(oldImageUrl));
                  }
                  _reload();
                }
              },
            ),
            ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
              ),
              title: Text('Delete',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade400)),
              subtitle: const Text('Remove this product permanently'),
              onTap: () async {
                Navigator.pop(context);
                await _confirmDelete(context, product);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, UserProductModel product,
      {bool dryRun = false}) async {
    final confirmed = await AppDialogs.warning(
      context,
      title: 'Delete Product',
      message: 'Delete "${product.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (dryRun) return confirmed;
    if (confirmed && product.id != null) {
      try {
        await _service.delete(product.id!);
        _reload();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left,
                        color: primaryColor, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Contributions',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                      Text('Products you added to the community',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<UserProductModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: primaryColor));
                }
                if (snap.hasError) {
                  return Center(
                      child: Text(snap.error.toString(),
                          style: const TextStyle(color: Colors.red)));
                }
                final products = snap.data ?? [];
                if (products.isEmpty) return _buildEmpty();
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => Dismissible(
                    key: ValueKey(products[i].id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(context, products[i], dryRun: true),
                    onDismissed: (_) async {
                      try {
                        await _service.delete(products[i].id!);
                        _reload();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red));
                        }
                      }
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(16),
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
                    child: InkWell(
                      onTap: () => _showOptions(context, products[i]),
                      borderRadius: BorderRadius.circular(16),
                      child: _ProductCard(product: products[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No contributions yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('When you scan an unknown product, you can add it',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final UserProductModel product;
  const _ProductCard({required this.product});

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(product.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(product.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.fastfood_outlined, color: Colors.grey, size: 22)),
                  )
                : const Icon(Icons.fastfood_outlined, color: Colors.grey, size: 22),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
                if (product.brand.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(product.brand,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusInfo.$2.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusInfo.$1,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusInfo.$2)),
                    ),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.thumb_up_outlined, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text('${product.confirmationCount}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(width: 6),
                      Icon(Icons.flag_outlined, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text('${product.flagCount}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                  ],
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  (String, Color) _statusInfo(String status) {
    switch (status) {
      case 'approved':
        return ('Approved', const Color(0xFF27AE60));
      case 'community_verified':
        return ('Community verified', const Color(0xFF2980B9));
      case 'rejected':
        return ('Rejected', const Color(0xFFE74C3C));
      default:
        return ('Pending review', const Color(0xFFF39C12));
    }
  }
}
