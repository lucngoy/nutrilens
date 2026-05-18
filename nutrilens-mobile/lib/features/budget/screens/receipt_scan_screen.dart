import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/currency_provider.dart';
import '../providers/budget_provider.dart';

class ReceiptScanScreen extends ConsumerStatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  ConsumerState<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends ConsumerState<ReceiptScanScreen> {
  static const primaryColor = Color(0xFFEC6F2D);

  File? _image;
  bool _scanning = false;
  bool _confirming = false;
  String? _error;

  // Parsed receipt data
  String? _store;
  String? _purchaseDate;
  List<_ReceiptLine> _lines = [];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _lines = [];
      _store = null;
      _purchaseDate = null;
      _error = null;
    });
    await _scanReceipt();
  }

  Future<void> _scanReceipt() async {
    if (_image == null) return;
    setState(() { _scanning = true; _error = null; });
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          _image!.path,
          filename: 'receipt.jpg',
        ),
      });
      final resp = await ApiClient.instance.post('/budget/receipt/scan/', data: form);
      final data = resp.data as Map<String, dynamic>;

      final rawLines = (data['lines'] as List? ?? []);
      setState(() {
        _store = data['store'] as String?;
        _purchaseDate = data['purchase_date'] as String?;
        _lines = rawLines.map((l) => _ReceiptLine(
          description: l['description'] ?? '',
          amount: (l['amount'] as num).toDouble(),
        )).toList();
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _error = _extractError(e);
        _scanning = false;
      });
    }
  }

  Future<void> _confirm() async {
    final confirmed = _lines.where((l) => l.included && l.amount > 0).toList();
    if (confirmed.isEmpty) return;

    setState(() { _confirming = true; _error = null; });
    try {
      final resp = await ApiClient.instance.post('/budget/receipt/confirm/', data: {
        'lines': confirmed.map((l) => {
          'description': l.description,
          'amount': l.amount,
        }).toList(),
        if (_purchaseDate != null) 'date': _purchaseDate,
        'store': _store ?? '',
      });

      final inserted = resp.data['inserted'] as int? ?? 0;
      await ref.read(budgetProvider.notifier).fetch();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$inserted expense${inserted == 1 ? '' : 's'} added to budget'),
          ]),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = _extractError(e);
        _confirming = false;
      });
    }
  }

  String _extractError(Object e) {
    if (e is DioException) {
      return e.response?.data?['error'] ?? e.message ?? 'Error';
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(currencyProvider.notifier).symbol;
    final hasResult = _lines.isNotEmpty;
    final confirmedCount = _lines.where((l) => l.included).length;

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
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left, color: primaryColor, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan Receipt',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A))),
                    Text('AI-powered expense import',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image picker card
                  _PickerCard(
                    image: _image,
                    scanning: _scanning,
                    onCamera: () => _pickImage(ImageSource.camera),
                    onGallery: () => _pickImage(ImageSource.gallery),
                    onRetake: () => _pickImage(ImageSource.camera),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE5E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 13)),
                    ),
                  ],

                  if (hasResult) ...[
                    const SizedBox(height: 16),

                    // Store + date info
                    if (_store != null || _purchaseDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          const Icon(Icons.store_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            [if (_store != null) _store!, if (_purchaseDate != null) _purchaseDate!]
                                .join('  •  '),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                          )),
                        ]),
                      ),

                    const SizedBox(height: 12),

                    // Lines
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                            child: Row(children: [
                              const Icon(Icons.receipt_long_outlined,
                                  size: 15, color: primaryColor),
                              const SizedBox(width: 8),
                              Text('${_lines.length} item${_lines.length == 1 ? '' : 's'} detected',
                                  style: const TextStyle(fontSize: 13,
                                      fontWeight: FontWeight.w700, color: Colors.black54)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() {
                                  final allOn = _lines.every((l) => l.included);
                                  for (final l in _lines) l.included = !allOn;
                                }),
                                child: Text(
                                  _lines.every((l) => l.included) ? 'Deselect all' : 'Select all',
                                  style: const TextStyle(fontSize: 12, color: primaryColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ]),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          ...List.generate(_lines.length, (i) {
                            final line = _lines[i];
                            return _LineRow(
                              line: line,
                              symbol: symbol,
                              onToggle: () => setState(() => line.included = !line.included),
                              onAmountChanged: (v) => setState(() => line.amount = v),
                              onDescChanged: (v) => setState(() => line.description = v),
                              showDivider: i < _lines.length - 1,
                            );
                          }),
                          if (_lines.any((l) => l.included)) ...[
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(children: [
                                const Text('Total to log',
                                    style: TextStyle(fontSize: 13,
                                        fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                                const Spacer(),
                                Text(
                                  '$symbol${_lines.where((l) => l.included).fold(0.0, (s, l) => s + l.amount).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 15,
                                      fontWeight: FontWeight.w800, color: primaryColor),
                                ),
                              ]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom confirm button
          if (hasResult)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              child: ElevatedButton(
                onPressed: (confirmedCount == 0 || _confirming) ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: _confirming
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Add $confirmedCount expense${confirmedCount == 1 ? '' : 's'} to budget',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _ReceiptLine {
  String description;
  double amount;
  bool included;
  _ReceiptLine({required this.description, required this.amount, this.included = true});
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PickerCard extends StatelessWidget {
  final File? image;
  final bool scanning;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRetake;
  const _PickerCard({
    required this.image, required this.scanning,
    required this.onCamera, required this.onGallery, required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    if (scanning) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFEC6F2D)),
            SizedBox(height: 16),
            Text('Analyzing receipt…',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    if (image != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(image!, width: double.infinity,
                height: 220, fit: BoxFit.cover),
          ),
          Positioned(
            top: 10, right: 10,
            child: GestureDetector(
              onTap: onRetake,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Retake', style: TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFEC6F2D).withOpacity(0.25), width: 1.5,
            style: BorderStyle.solid),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEC6F2D).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 30, color: Color(0xFFEC6F2D)),
          ),
          const SizedBox(height: 16),
          const Text('Take a photo of your receipt',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('AI will extract items and amounts automatically',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  side: const BorderSide(color: Color(0xFFEEEEEE)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                label: const Text('Camera',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC6F2D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final _ReceiptLine line;
  final String symbol;
  final VoidCallback onToggle;
  final ValueChanged<double> onAmountChanged;
  final ValueChanged<String> onDescChanged;
  final bool showDivider;

  const _LineRow({
    required this.line, required this.symbol,
    required this.onToggle, required this.onAmountChanged,
    required this.onDescChanged, required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  line.included
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: line.included
                      ? const Color(0xFF27AE60)
                      : Colors.grey.shade300,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    line.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: line.included ? const Color(0xFF1A1A1A) : Colors.grey,
                      decoration: line.included ? null : TextDecoration.lineThrough,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$symbol${line.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: line.included ? const Color(0xFF1A1A1A) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 50, endIndent: 16),
      ],
    );
  }
}
