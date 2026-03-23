import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/scanner_provider.dart';
import 'product_detail_screen.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _torchOn = false;
  late AnimationController _scanAnimController;
  late Animation<double> _scanAnim;

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanAnimController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    setState(() => _isProcessing = true);
    await _controller.stop();

    await ref.read(scannedProductProvider.notifier).fetchProduct(barcode);

    if (!mounted) return;

    final productState = ref.read(scannedProductProvider);

    productState.when(
      data: (product) {
        if (product != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product)),
          ).then((_) {
            ref.read(scannedProductProvider.notifier).reset();
            _controller.start();
            setState(() => _isProcessing = false);
          });
        } else {
          _showSnackbar('Product not found in database.', Colors.orange);
          _controller.start();
          setState(() => _isProcessing = false);
        }
      },
      loading: () {},
      error: (e, _) {
        _showSnackbar(e.toString(), Colors.red);
        _controller.start();
        setState(() => _isProcessing = false);
      },
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showManualEntry() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Barcode',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. 3017620422003',
                hintStyle:
                    const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.qr_code,
                    color: Colors.grey, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: primaryColor, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    Navigator.pop(context);
                    _onBarcodeDetected(BarcodeCapture(
                      barcodes: [
                        Barcode(rawValue: controller.text)
                      ],
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Search Product',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(scannedProductProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),

          // Dark overlay with scan frame
          CustomPaint(
            painter: _OverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Animated scan line
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (_, __) {
              final scanArea = Rect.fromCenter(
                center: Offset(
                    MediaQuery.of(context).size.width / 2,
                    MediaQuery.of(context).size.height / 2 - 60),
                width: 260,
                height: 180,
              );
              return Positioned(
                top: scanArea.top + _scanAnim.value * scanArea.height,
                left: scanArea.left + 4,
                right: MediaQuery.of(context).size.width -
                    scanArea.right +
                    4,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.8),
                    boxShadow: [
                      BoxShadow(
                          color: primaryColor.withOpacity(0.5),
                          blurRadius: 6),
                    ],
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            },
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  _CircleButton(
                    icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                    onTap: () {
                      _controller.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Center instructions
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 160),
                if (isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Fetching product...',
                            style: TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Bottom text + manual entry
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  const Text('Align barcode within frame',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text(
                      'Position the barcode clearly within the scanning area',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _showManualEntry,
                      icon: const Icon(Icons.keyboard, size: 20),
                      label: const Text('Enter Barcode Manually',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A1A1A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  static const primaryColor = Color(0xFFEC6F2D);

  @override
  void paint(Canvas canvas, Size size) {
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 60),
      width: 260,
      height: 180,
    );

    // Dark overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
              RRect.fromRectAndRadius(scanArea, const Radius.circular(12))),
      ),
      Paint()..color = Colors.black54,
    );

    // Border frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanArea, const Radius.circular(12)),
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Corner brackets
    final p = Paint()
      ..color = primaryColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const c = 28.0;
    // Top-left
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + const Offset(c, 0), p);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + const Offset(0, c), p);
    // Top-right
    canvas.drawLine(
        scanArea.topRight, scanArea.topRight + const Offset(-c, 0), p);
    canvas.drawLine(
        scanArea.topRight, scanArea.topRight + const Offset(0, c), p);
    // Bottom-left
    canvas.drawLine(
        scanArea.bottomLeft, scanArea.bottomLeft + const Offset(c, 0), p);
    canvas.drawLine(
        scanArea.bottomLeft, scanArea.bottomLeft + const Offset(0, -c), p);
    // Bottom-right
    canvas.drawLine(
        scanArea.bottomRight, scanArea.bottomRight + const Offset(-c, 0), p);
    canvas.drawLine(
        scanArea.bottomRight, scanArea.bottomRight + const Offset(0, -c), p);
  }

  @override
  bool shouldRepaint(_) => false;
}