class AnalysisWarning {
  final String code;
  final String label;
  final String severity; // 'danger' | 'warning' | 'info'
  final String detail;

  const AnalysisWarning({
    required this.code,
    required this.label,
    required this.severity,
    required this.detail,
  });

  factory AnalysisWarning.fromJson(Map<String, dynamic> json) {
    return AnalysisWarning(
      code: json['code'] ?? '',
      label: json['label'] ?? '',
      severity: json['severity'] ?? 'warning',
      detail: json['detail'] ?? '',
    );
  }

  bool get isDanger => severity == 'danger';
}

class AnalysisResult {
  final List<AnalysisWarning> warnings;
  final List<String> highlightedIngredients;
  final List<String> recommendations;
  final List<String> reasons;
  final int score;

  const AnalysisResult({
    required this.warnings,
    required this.highlightedIngredients,
    required this.recommendations,
    required this.reasons,
    required this.score,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      warnings: (json['warnings'] as List? ?? [])
          .map((w) => AnalysisWarning.fromJson(w))
          .toList(),
      highlightedIngredients:
          (json['highlighted_ingredients'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
      recommendations: (json['recommendations'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      reasons: (json['reasons'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      score: json['score'] ?? 100,
    );
  }

  bool get hasDanger => warnings.any((w) => w.isDanger);
  bool get isClean => warnings.isEmpty;
}
