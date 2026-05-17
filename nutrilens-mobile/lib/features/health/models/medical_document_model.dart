class DocumentAnalysis {
  final int id;
  final double? bloodGlucose;
  final double? hba1c;
  final double? cholesterolTotal;
  final double? cholesterolLdl;
  final double? cholesterolHdl;
  final double? triglycerides;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final double? vitaminD;
  final double? vitaminB12;
  final double? ferritin;
  final String summary;
  final List<String> keyFindings;
  final List<Map<String, dynamic>> dietaryRecommendations;
  final DateTime analyzedAt;

  DocumentAnalysis({
    required this.id,
    this.bloodGlucose,
    this.hba1c,
    this.cholesterolTotal,
    this.cholesterolLdl,
    this.cholesterolHdl,
    this.triglycerides,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.vitaminD,
    this.vitaminB12,
    this.ferritin,
    required this.summary,
    required this.keyFindings,
    required this.dietaryRecommendations,
    required this.analyzedAt,
  });

  factory DocumentAnalysis.fromJson(Map<String, dynamic> json) {
    return DocumentAnalysis(
      id: json['id'],
      bloodGlucose: json['blood_glucose']?.toDouble(),
      hba1c: json['hba1c']?.toDouble(),
      cholesterolTotal: json['cholesterol_total']?.toDouble(),
      cholesterolLdl: json['cholesterol_ldl']?.toDouble(),
      cholesterolHdl: json['cholesterol_hdl']?.toDouble(),
      triglycerides: json['triglycerides']?.toDouble(),
      bloodPressureSystolic: json['blood_pressure_systolic'],
      bloodPressureDiastolic: json['blood_pressure_diastolic'],
      vitaminD: json['vitamin_d']?.toDouble(),
      vitaminB12: json['vitamin_b12']?.toDouble(),
      ferritin: json['ferritin']?.toDouble(),
      summary: json['summary'] ?? '',
      keyFindings: List<String>.from(json['key_findings'] ?? []),
      dietaryRecommendations: (json['dietary_recommendations'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      analyzedAt: DateTime.parse(json['analyzed_at']),
    );
  }
}

class MedicalDocument {
  final int id;
  final String title;
  final String documentType;
  final String file;
  final String notes;
  final DateTime uploadedAt;
  final DocumentAnalysis? analysis;

  MedicalDocument({
    required this.id,
    required this.title,
    required this.documentType,
    required this.file,
    required this.notes,
    required this.uploadedAt,
    this.analysis,
  });

  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    return MedicalDocument(
      id: json['id'],
      title: json['title'] ?? '',
      documentType: json['document_type'] ?? 'other',
      file: json['file'] ?? '',
      notes: json['notes'] ?? '',
      uploadedAt: DateTime.parse(json['uploaded_at']),
      analysis: json['analysis'] != null
          ? DocumentAnalysis.fromJson(json['analysis'])
          : null,
    );
  }

  MedicalDocument copyWith({String? title, String? notes}) {
    return MedicalDocument(
      id: id,
      title: title ?? this.title,
      documentType: documentType,
      file: file,
      notes: notes ?? this.notes,
      uploadedAt: uploadedAt,
      analysis: analysis,
    );
  }

  String get documentTypeLabel {
    switch (documentType) {
      case 'blood_test': return 'Blood Test';
      case 'prescription': return 'Prescription';
      case 'report': return 'Medical Report';
      default: return 'Other';
    }
  }
}
