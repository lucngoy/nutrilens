import '../../../core/network/api_client.dart';

class MedicalConsentService {
  static Future<void> accept() async {
    await ApiClient.instance.post('/users/medical-consent/');
  }
}
