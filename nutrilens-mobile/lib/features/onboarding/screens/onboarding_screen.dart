import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const primaryColor = Color(0xFFEC6F2D);

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      step: '01 / 03',
      title: 'Scan any product,',
      titleAccent: 'know what\'s inside',
      description:
          'Point your camera at any barcode to instantly access full nutritional data and health insights.',
      illustration: _Illustration.scanner,
    ),
    _OnboardingData(
      step: '02 / 03',
      title: 'Your health,',
      titleAccent: 'always in check',
      description:
          'Set your profile once — allergies, conditions, goals. NutriLens does the rest automatically.',
      illustration: _Illustration.health,
    ),
    _OnboardingData(
      step: '03 / 03',
      title: 'Your smart',
      titleAccent: 'nutrition coach',
      description:
          'Get personalized meal plans, dietary recommendations and smart alerts — all tailored to your health.',
      illustration: _Illustration.ai,
    ),
  ];

  void _next() {
    if (_currentPage < 2) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  void _skip() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardingPage(
                  data: _pages[i],
                  primaryColor: primaryColor,
                  onSkip: _skip,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      height: 4,
                      width: i == _currentPage ? 24 : 8,
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? primaryColor
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 2 ? 'Get Started' : 'Next',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_right, size: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Illustration { scanner, health, ai }

class _OnboardingData {
  final String step;
  final String title;
  final String titleAccent;
  final String description;
  final _Illustration illustration;

  const _OnboardingData({
    required this.step,
    required this.title,
    required this.titleAccent,
    required this.description,
    required this.illustration,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final Color primaryColor;
  final VoidCallback onSkip;

  const _OnboardingPage({
    required this.data,
    required this.primaryColor,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data.step,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: 0.08)),
              TextButton(
                onPressed: onSkip,
                child: const Text('Skip',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildIllustration(data.illustration, primaryColor)),
          const SizedBox(height: 24),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  height: 1.2,
                  letterSpacing: -0.5),
              children: [
                TextSpan(text: '${data.title}\n'),
                TextSpan(
                    text: data.titleAccent,
                    style: TextStyle(color: primaryColor)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(data.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, color: Colors.grey, height: 1.65)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildIllustration(_Illustration type, Color color) {
    switch (type) {
      case _Illustration.scanner:
        return _ScannerIllustration(color: color);
      case _Illustration.health:
        return _HealthIllustration(color: color);
      case _Illustration.ai:
        return _AIIllustration(color: color);
    }
  }
}

class _ScannerIllustration extends StatefulWidget {
  final Color color;
  const _ScannerIllustration({required this.color});
  @override
  State<_ScannerIllustration> createState() => _ScannerIllustrationState();
}

class _ScannerIllustrationState extends State<_ScannerIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _scale,
              builder: (_, __) => Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: widget.color.withOpacity(0.15), width: 1.5),
                  ),
                ),
              ),
            ),
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: widget.color.withOpacity(0.1), width: 1),
              ),
            ),
            Container(
              width: 140,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: widget.color.withOpacity(0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 8)),
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
                border: Border.all(
                    color: widget.color.withOpacity(0.08), width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(child: Text('🥫', style: TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(height: 10),
                  const Text('Tomato Soup',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 2),
                  const Text('142 kcal',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Container(
                    width: 100,
                    height: 3,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(2)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.72,
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [widget.color, const Color(0xFFFF6B47)]),
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 20,
              right: 0,
              child: _Chip(text: '✓ Gluten-free', color: Colors.green),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              child: _Chip(text: '⚠ High sugar', color: widget.color),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _HealthIllustration extends StatelessWidget {
  final Color color;
  const _HealthIllustration({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _HealthCard(label: 'BMI', value: '22.4', unit: 'Normal', icon: '⚖️', progress: 0.65, color: color)),
                const SizedBox(width: 10),
                Expanded(child: _HealthCard(label: 'Calories', value: '1,420', unit: 'of 1,800', icon: '🔥', progress: 0.79, color: color)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _HealthCard(label: 'Protein', value: '68g', unit: 'of 90g', icon: '💪', progress: 0.75, color: color)),
                const SizedBox(width: 10),
                Expanded(child: _HealthCard(label: 'Alerts', value: '2', unit: 'allergens', icon: '⚠️', progress: 0.30, color: Colors.amber)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF0F0F0)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CustomPaint(painter: _CircleProgressPainter(0.7, color)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Weekly health goal', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('On track — great work!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final String label, value, unit, icon;
  final double progress;
  final Color color;
  const _HealthCard({required this.label, required this.value, required this.unit, required this.icon, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(icon, style: const TextStyle(fontSize: 16)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          Text(unit, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF5F5F5),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _CircleProgressPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    paint.color = const Color(0xFFF0F0F0);
    canvas.drawCircle(center, radius, paint);
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, 2 * 3.14159 * progress, false, paint,
    );
    final tp = TextPainter(
      text: TextSpan(text: '${(progress * 100).round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_) => false;
}

class _AIIllustration extends StatelessWidget {
  final Color color;
  const _AIIllustration({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0F0F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('NutriAI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                  Text('Personal coach', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
                const Spacer(),
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 14),
              _ChatBubble(text: 'Not enough protein today. Want a suggestion?', isAI: true, color: color),
              const SizedBox(height: 8),
              _ChatBubble(text: 'Yes, something quick!', isAI: false, color: color),
              const SizedBox(height: 8),
              _ChatBubble(text: 'Try Greek yogurt + almonds — 28g protein ✓', isAI: true, color: color),
              const SizedBox(height: 8),
              _ChatBubble(text: 'Perfect, adding to my plan!', isAI: false, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isAI;
  final Color color;
  const _ChatBubble({required this.text, required this.isAI, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAI ? const Color(0xFFF7F7F7) : color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isAI ? 4 : 14),
            bottomRight: Radius.circular(isAI ? 14 : 4),
          ),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                color: isAI ? const Color(0xFF333333) : Colors.white,
                height: 1.5)),
      ),
    );
  }
}