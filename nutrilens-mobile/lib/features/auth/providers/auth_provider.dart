import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../features/inventory/providers/inventory_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(ref.read(authServiceProvider), ref),
);

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final loggedIn = await StorageService.isLoggedIn();
    if (loggedIn) {
      try {
        final user = await _authService.getProfile();
        state = AsyncValue.data(user);
        _ref.read(inventoryProvider.notifier).fetchInventory();
      } catch (_) {
        state = const AsyncValue.data(null);
      }
    } else {
      state = const AsyncValue.data(null);
    }
  }

    Future<void> login(String username, String password) async {
        try {
            await _authService.login(username: username, password: password);
            final user = await _authService.getProfile();
            state = AsyncValue.data(user);
            _ref.read(inventoryProvider.notifier).fetchInventory();
        } catch (e) {
            state = const AsyncValue.data(null);
            rethrow;
        }
    }

    Future<void> register(String username, String email, String password) async {
        try {
            await _authService.register(
                username: username, email: email, password: password);
            await login(username, password);
        } catch (e) {
            state = const AsyncValue.data(null);
            rethrow;
        }
    }

    Future<void> logout() async {
        await _authService.logout();
        _ref.invalidate(inventoryProvider);
        state = const AsyncValue.data(null);
    }
}