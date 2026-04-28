import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const kCurrencies = [
  ('USD', r'$',    'US Dollar'),
  ('EUR', '€',    'Euro'),
  ('GBP', '£',    'British Pound'),
  ('CAD', r'CA$', 'Canadian Dollar'),
  ('XAF', 'FCFA', 'CFA Franc BEAC'),
  ('XOF', 'FCFA', 'CFA Franc BCEAO'),
  ('MAD', 'MAD',  'Moroccan Dirham'),
  ('NGN', '₦',    'Nigerian Naira'),
  ('GHS', 'GH₵',  'Ghanaian Cedi'),
  ('TRY', '₺',    'Turkish Lira'),
];

const _kCurrencyKey = 'selected_currency_code';

final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, String>((ref) => CurrencyNotifier());

class CurrencyNotifier extends StateNotifier<String> {
  final _storage = const FlutterSecureStorage();

  CurrencyNotifier() : super('USD') {
    _load();
  }

  Future<void> _load() async {
    final saved = await _storage.read(key: _kCurrencyKey);
    if (saved != null && kCurrencies.any((c) => c.$1 == saved)) {
      state = saved;
    }
  }

  Future<void> setCurrency(String code) async {
    state = code;
    await _storage.write(key: _kCurrencyKey, value: code);
  }

  String get symbol =>
      kCurrencies.firstWhere((c) => c.$1 == state, orElse: () => kCurrencies.first).$2;
}
