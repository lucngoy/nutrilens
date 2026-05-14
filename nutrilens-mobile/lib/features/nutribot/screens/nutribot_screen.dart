import 'package:flutter/material.dart';
import '../services/nutribot_service.dart';
import '../../scanner/models/product_model.dart';

class NutriBotScreen extends StatefulWidget {
  final ProductModel? product;
  const NutriBotScreen({super.key, this.product});

  @override
  State<NutriBotScreen> createState() => _NutriBotScreenState();
}

class _NutriBotScreenState extends State<NutriBotScreen> {
  static const primaryColor = Color(0xFFEC6F2D);

  final _service = NutriBotService();
  final _messages = <NutriBotMessage>[];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendProductContext());
    }
  }

  void _sendProductContext() {
    final p = widget.product!;
    final n = p.nutrition;
    final parts = <String>['I just scanned ${p.name}'];
    if (p.brand != null) parts.add('by ${p.brand}');
    parts.add('.');
    if (n.calories != null) parts.add('It has ${n.calories!.toStringAsFixed(0)} kcal');
    if (n.protein != null) parts.add(', ${n.protein!.toStringAsFixed(1)}g protein');
    if (n.carbohydrates != null) parts.add(', ${n.carbohydrates!.toStringAsFixed(1)}g carbs');
    if (n.fat != null) parts.add(', ${n.fat!.toStringAsFixed(1)}g fat');
    parts.add('. Is this product suitable for my diet?');
    _inputCtrl.text = parts.join('');
    _send();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(NutriBotMessage(role: 'user', content: text));
      _loading = true;
      _error = null;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    try {
      final reply = await _service.send(message: text, history: _messages);
      setState(() {
        _messages.add(NutriBotMessage(role: 'assistant', content: reply));
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = 'Failed to get a response. Please try again.';
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black87, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NutriBot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                Text('Powered by Llama 3', style: TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ]),
        ),
        body: SafeArea(
          child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _messages.length) return _buildTypingIndicator();
                        return _buildBubble(_messages[i]);
                      },
                    ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            _buildInputBar(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined, color: primaryColor, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Ask NutriBot anything',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Nutrition advice, meal ideas, ingredient questions — all personalized to your profile.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black45)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                'How much protein do I need?',
                'What can I eat before a workout?',
                'Is olive oil healthy?',
                'Good snacks for weight loss?',
              ].map((q) => GestureDetector(
                onTap: () {
                  _inputCtrl.text = q;
                  _send();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Text(q, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(NutriBotMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : const Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 40, height: 12,
              child: _TypingDots(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask NutriBot…',
                hintStyle: const TextStyle(color: Colors.black38),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _loading ? Colors.grey.shade300 : primaryColor,
                shape: BoxShape.circle,
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final offset = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final opacity = (1 - (offset - 0.5).abs() * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: Color(0xFFEC6F2D), shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
