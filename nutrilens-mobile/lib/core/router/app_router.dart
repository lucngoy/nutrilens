import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/scanner/screens/scanner_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/inventory/screens/add_inventory_screen.dart';
import '../../features/scanner/models/product_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (isLoading) return null;
      if (isLoggedIn && (isAuthRoute || isOnboarding)) return '/home';
      if (!isLoggedIn && (isAuthRoute || isOnboarding)) return null;
      if (!isLoggedIn) return '/login';
      return null;
    },
    routes: [
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: '/scanner',
          builder: (context, state) => const ScannerScreen()),
      GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryScreen()),
      GoRoute(
          path: '/inventory/add',
          builder: (context, state) {
            final product = state.extra as ProductModel;
            return AddInventoryScreen(product: product);
          }),
    ],
  );
});