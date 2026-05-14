import '../../../core/network/api_client.dart';

class NutriBotMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  NutriBotMessage({required this.role, required this.content})
      : timestamp = DateTime.now();
}

class NutriBotService {
  final _dio = ApiClient.instance;

  Future<String> send({
    required String message,
    required List<NutriBotMessage> history,
  }) async {
    final response = await _dio.post(
      '/users/nutribot/',
      data: {
        'message': message,
        'history': history
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
      },
    );
    return response.data['reply'] as String;
  }
}
