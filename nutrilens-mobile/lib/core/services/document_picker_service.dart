import 'dart:io';
import 'package:flutter/services.dart';

class DocumentPickerService {
  static const _channel = MethodChannel('com.nutrilens/document_picker');

  /// Opens native iOS document picker (PDF, DOC, DOCX, TXT).
  /// Returns null if cancelled.
  static Future<File?> pickDocument() async {
    try {
      final path = await _channel.invokeMethod<String>('pickDocument');
      if (path == null) return null;
      return File(path);
    } on PlatformException {
      return null;
    }
  }
}
