import 'package:flutter/material.dart';
import '../models/medical_document_model.dart';
import '../widgets/medical_disclaimer.dart';

class DocumentAnalysisScreen extends StatelessWidget {
  final MedicalDocument document;
  const DocumentAnalysisScreen({super.key, required this.document});

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    final a = document.analysis!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          // Header — cohérent avec le reste de l'app
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A)),
                      ),
                      Text(
                        document.documentTypeLabel,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
          // AI badge
          const AiDisclaimerBadge(),
          const SizedBox(height: 16),

          // Summary
          if (a.summary.isNotEmpty)
            _Card(
              icon: Icons.summarize_outlined,
              title: 'Summary',
              child: Text(a.summary,
                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
            ),

          // Biomarkers
          _Card(
            icon: Icons.biotech_outlined,
            title: 'Biomarkers',
            child: Column(
              children: [
                if (a.bloodGlucose != null)
                  _BioRow('Blood glucose', '${a.bloodGlucose} mmol/L', _glucoseStatus(a.bloodGlucose!)),
                if (a.hba1c != null)
                  _BioRow('HbA1c', '${a.hba1c}%', _hba1cStatus(a.hba1c!)),
                if (a.cholesterolTotal != null)
                  _BioRow('Total cholesterol', '${a.cholesterolTotal} mmol/L', _cholesterolStatus(a.cholesterolTotal!)),
                if (a.cholesterolLdl != null)
                  _BioRow('LDL', '${a.cholesterolLdl} mmol/L', _ldlStatus(a.cholesterolLdl!)),
                if (a.cholesterolHdl != null)
                  _BioRow('HDL', '${a.cholesterolHdl} mmol/L', _hdlStatus(a.cholesterolHdl!)),
                if (a.triglycerides != null)
                  _BioRow('Triglycerides', '${a.triglycerides} mmol/L', _triglyceridesStatus(a.triglycerides!)),
                if (a.bloodPressureSystolic != null)
                  _BioRow('Blood pressure', '${a.bloodPressureSystolic}/${a.bloodPressureDiastolic} mmHg',
                      _bpStatus(a.bloodPressureSystolic!)),
                if (a.vitaminD != null)
                  _BioRow('Vitamin D', '${a.vitaminD} ng/mL', _vitaminDStatus(a.vitaminD!)),
                if (a.vitaminB12 != null)
                  _BioRow('Vitamin B12', '${a.vitaminB12} pg/mL', _normal),
                if (a.ferritin != null)
                  _BioRow('Ferritin', '${a.ferritin} ng/mL', _normal),
              ],
            ),
          ),

          // Key findings
          if (a.keyFindings.isNotEmpty)
            _Card(
              icon: Icons.search_outlined,
              title: 'Key Findings',
              child: Column(
                children: a.keyFindings.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 6, color: primaryColor),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f,
                          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4))),
                    ],
                  ),
                )).toList(),
              ),
            ),

          // Dietary recommendations
          if (a.dietaryRecommendations.isNotEmpty)
            _Card(
              icon: Icons.restaurant_menu_outlined,
              title: 'Dietary Recommendations',
              child: Column(
                children: a.dietaryRecommendations.map((r) {
                  final rec = r['recommendation'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check, size: 14, color: primaryColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(rec,
                            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

              const SizedBox(height: 8),
              const AiDisclaimerBadge(),
              const SizedBox(height: 20),
            ],
          ),
          ),
        ],
      ),
    );
  }

  static const _normal = _BioStatus.normal;

  _BioStatus _glucoseStatus(double v) =>
      v < 4.0 ? _BioStatus.low : v > 7.0 ? _BioStatus.high : _BioStatus.normal;

  _BioStatus _hba1cStatus(double v) =>
      v >= 6.5 ? _BioStatus.high : v >= 5.7 ? _BioStatus.warning : _BioStatus.normal;

  _BioStatus _cholesterolStatus(double v) =>
      v > 5.2 ? _BioStatus.warning : _BioStatus.normal;

  _BioStatus _ldlStatus(double v) =>
      v > 3.4 ? _BioStatus.warning : _BioStatus.normal;

  _BioStatus _hdlStatus(double v) =>
      v < 1.0 ? _BioStatus.low : _BioStatus.normal;

  _BioStatus _triglyceridesStatus(double v) =>
      v > 1.7 ? _BioStatus.warning : _BioStatus.normal;

  _BioStatus _bpStatus(int systolic) =>
      systolic >= 140 ? _BioStatus.high : systolic >= 120 ? _BioStatus.warning : _BioStatus.normal;

  _BioStatus _vitaminDStatus(double v) =>
      v < 20 ? _BioStatus.low : v < 30 ? _BioStatus.warning : _BioStatus.normal;
}

enum _BioStatus { normal, warning, high, low }

class _BioRow extends StatelessWidget {
  final String label;
  final String value;
  final _BioStatus status;
  const _BioRow(this.label, this.value, this.status);

  Color get _color {
    switch (status) {
      case _BioStatus.high:    return Colors.red;
      case _BioStatus.warning: return Colors.orange;
      case _BioStatus.low:     return Colors.blue;
      case _BioStatus.normal:  return Colors.green;
    }
  }

  String get _label {
    switch (status) {
      case _BioStatus.high:    return 'High';
      case _BioStatus.warning: return 'Borderline';
      case _BioStatus.low:     return 'Low';
      case _BioStatus.normal:  return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(label,
          style: const TextStyle(fontSize: 13, color: Colors.black54))),
      Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(_label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color)),
      ),
    ]),
  );
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Card({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: const Color(0xFFEC6F2D)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54)),
        ]),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}
