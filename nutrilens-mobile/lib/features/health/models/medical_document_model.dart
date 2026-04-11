class MedicalDocument {
  final int id;
  final String title;
  final String documentType;
  final String file;
  final String notes;
  final DateTime uploadedAt;

  MedicalDocument({
    required this.id,
    required this.title,
    required this.documentType,
    required this.file,
    required this.notes,
    required this.uploadedAt,
  });

  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    return MedicalDocument(
      id: json['id'],
      title: json['title'] ?? '',
      documentType: json['document_type'] ?? 'other',
      file: json['file'] ?? '',
      notes: json['notes'] ?? '',
      uploadedAt: DateTime.parse(json['uploaded_at']),
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
