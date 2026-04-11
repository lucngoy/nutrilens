import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/scan_history_provider.dart';
import '../models/scan_history_model.dart';

class ScanHistoryScreen extends ConsumerStatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  ConsumerState<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen> {
  static const primaryColor = Color(0xFFEC6F2D);

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(scanHistoryProvider.notifier).fetchRecentScans(limit: 50));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
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
                    const Text('Scan History',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A))),
                  ],
                ),
                state.whenOrNull(
                      data: (scans) => Text('${scans.length} scans',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                    ) ??
                    const SizedBox(),
              ],
            ),
          ),

          // Body
          Expanded(
            child: state.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
              error: (_, __) => const Center(
                child: Text('Unable to load history',
                    style: TextStyle(color: Colors.grey)),
              ),
              data: (scans) => scans.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      itemCount: scans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ScanItem(scan: scans[i]),
                    ),
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
          Icon(Icons.history, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No scans yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('Scan your first product to see it here',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ScanItem extends StatelessWidget {
  final ScanHistoryItem scan;
  const _ScanItem({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: scan.imageUrl != null && scan.imageUrl!.isNotEmpty
                ? Image.network(
                    scan.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
                if (scan.brand.isNotEmpty)
                  Text(scan.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(_timeAgo(scan.scannedAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          if (scan.nutriscore != null)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _scoreColor(scan.nutriscore!.toUpperCase()),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  scan.nutriscore!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
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
    switch (s) {
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
}
