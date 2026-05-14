import 'package:flutter/material.dart';
import '../services/medical_consent_service.dart';

/// Shows the medical consent modal.
/// Returns true if the user accepted, false if dismissed.
Future<bool> showMedicalConsentModal(BuildContext context) async {
  bool checked = false;
  bool saving = false;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.health_and_safety_outlined,
                    color: Colors.red.shade400, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text('Medical Data Disclaimer',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 16),

            // Body
            const Text(
              'NutriLens uses AI to analyze your medical documents and provide '
              'personalized nutrition insights. Please read carefully:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            _DisclaimerPoint(
              icon: Icons.smart_toy_outlined,
              text: 'Analysis is performed by AI and may not be 100% accurate.',
            ),
            _DisclaimerPoint(
              icon: Icons.medical_services_outlined,
              text: 'This is NOT a substitute for professional medical advice.',
            ),
            _DisclaimerPoint(
              icon: Icons.lock_outline,
              text: 'Your documents are stored securely and never shared.',
            ),
            _DisclaimerPoint(
              icon: Icons.warning_amber_outlined,
              text: 'Always consult your doctor before making health decisions.',
            ),

            const SizedBox(height: 20),

            // Checkbox
            GestureDetector(
              onTap: () => setState(() => checked = !checked),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: checked,
                    onChanged: (v) => setState(() => checked = v ?? false),
                    activeColor: const Color(0xFFEC6F2D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'I understand that NutriLens AI analysis is for informational '
                        'purposes only and is not a substitute for professional medical advice.',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (!checked || saving)
                    ? null
                    : () async {
                        setState(() => saving = true);
                        try {
                          await MedicalConsentService.accept();
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (_) {
                          setState(() => saving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC6F2D),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('I Understand & Accept',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.black45)),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return result ?? false;
}

class _DisclaimerPoint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DisclaimerPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.black38),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ),
      ],
    ),
  );
}

/// Inline disclaimer badge — use below any AI-generated analysis.
class AiDisclaimerBadge extends StatelessWidget {
  const AiDisclaimerBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, size: 14, color: Colors.black38),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'AI-generated — Not medical advice. Consult your doctor before making health decisions.',
            style: TextStyle(fontSize: 11, color: Colors.black38),
          ),
        ),
      ],
    ),
  );
}
