import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/admin_notification_service.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen>
    with SingleTickerProviderStateMixin {
  static const primaryColor = Color(0xFFEC6F2D);
  late TabController _tabController;

  final _tabs = const ['pending', 'community_verified', 'approved', 'rejected'];
  final _tabLabels = const ['Pending', 'Community', 'Approved', 'Rejected'];

  Map<String, int> _counts = {};
  int _refreshTrigger = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    AdminNotificationService.resetCount();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    try {
      final results = await Future.wait(
        _tabs.map((s) => ApiClient.instance
            .get('/inventory/admin/products/', queryParameters: {'status': s})),
      );
      if (mounted) {
        setState(() {
          for (int i = 0; i < _tabs.length; i++) {
            _counts[_tabs[i]] = (results[i].data as List).length;
          }
        });
      }
    } catch (_) {}
  }

  void _onReviewed() {
    setState(() => _refreshTrigger++);
    _fetchCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Product Moderation',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A))),
                        Text('Review community contributions',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: primaryColor,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: List.generate(_tabs.length, (i) {
                    final count = _counts[_tabs[i]] ?? 0;
                    final showBadge = count > 0 &&
                        (_tabs[i] == 'pending' || _tabs[i] == 'community_verified');
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_tabLabels[i]),
                          if (showBadge) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: _tabs[i] == 'community_verified'
                                    ? const Color(0xFF2980B9)
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((s) => _ProductList(
                        key: ValueKey('$s-$_refreshTrigger'),
                        statusFilter: s,
                        onReviewed: _onReviewed,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductList extends StatefulWidget {
  final String statusFilter;
  final VoidCallback? onReviewed;
  const _ProductList({super.key, required this.statusFilter, this.onReviewed});

  @override
  State<_ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<_ProductList> {
  static const primaryColor = Color(0xFFEC6F2D);

  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient.instance.get(
        '/inventory/admin/products/',
        queryParameters: {'status': widget.statusFilter},
      );
      setState(() {
        _products = List<Map<String, dynamic>>.from(resp.data);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _review(int id, String action) async {
    // Optimistic update — remove immediately so UI is instant
    final removed = _products.firstWhere((p) => p['id'] == id, orElse: () => {});
    setState(() => _products.removeWhere((p) => p['id'] == id));
    try {
      await ApiClient.instance.post(
        '/inventory/admin/products/$id/review/',
        data: {'action': action},
      );
      widget.onReviewed?.call();
    } catch (e) {
      // Restore on error
      if (removed.isNotEmpty && mounted) {
        setState(() => _products.insert(0, removed));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          TextButton(onPressed: _fetch, child: const Text('Retry')),
        ]),
      );
    }
    if (_products.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No ${widget.statusFilter} products',
              style: const TextStyle(color: Colors.grey)),
        ]),
      );
    }
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _fetch,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ReviewCard(
          product: _products[i],
          onReview: _review,
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Future<void> Function(int id, String action) onReview;

  const _ReviewCard({required this.product, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['image'] as String?;
    final status = product['status'] as String;
    final confirmations = product['confirmation_count'] ?? 0;
    final flags = product['flag_count'] ?? 0;
    final id = product['id'] as int;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + basic info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.fastfood_outlined,
                                      color: Colors.grey, size: 24)))
                      : const Icon(Icons.fastfood_outlined,
                          color: Colors.grey, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                      if ((product['brand'] ?? '').isNotEmpty)
                        Text(product['brand'],
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('By ${product['submitted_by'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 10),
                        Icon(Icons.thumb_up_outlined,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text('$confirmations',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 6),
                        Icon(Icons.flag_outlined,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text('$flags',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nutrition summary
          if (_hasNutrition())
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Macro('Cal', product['calories']),
                  _Macro('Protein', product['protein']),
                  _Macro('Carbs', product['carbohydrates']),
                  _Macro('Fat', product['fat']),
                ],
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                if (status == 'pending' || status == 'community_verified') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onReview(id, 'approve'),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onReview(id, 'reject'),
                      icon: Icon(Icons.close_rounded,
                          size: 16, color: Colors.red.shade400),
                      label: Text('Reject',
                          style: TextStyle(color: Colors.red.shade400)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onReview(id, 'pending'),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Reset to pending'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasNutrition() =>
      product['calories'] != null ||
      product['protein'] != null ||
      product['carbohydrates'] != null ||
      product['fat'] != null;
}

class _Macro extends StatelessWidget {
  final String label;
  final dynamic value;
  const _Macro(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final v = value != null ? '${(value as num).toStringAsFixed(0)}' : '—';
    return Column(
      children: [
        Text(v,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A))),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
