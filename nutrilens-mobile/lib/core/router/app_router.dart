import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/scanner/screens/scanner_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/health/screens/health_profile_screen.dart';
import '../../features/health/screens/health_history_screen.dart';
import '../../features/health/screens/medical_documents_screen.dart';
import '../../features/scanner/screens/scan_history_screen.dart';
import '../../features/inventory/screens/add_inventory_screen.dart';
import '../../features/inventory/screens/inventory_detail_screen.dart';
import '../../features/inventory/models/inventory_model.dart';
import '../../features/scanner/models/product_model.dart';
import '../../features/nutrition/screens/food_intake_screen.dart';
import '../../features/nutrition/screens/weekly_report_screen.dart';

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final location = state.matchedLocation;

      final isAuthRoute = location == '/login' || location == '/register';
      final isOnboarding = location == '/onboarding';

      if (isLoading) return null;
      if (isLoggedIn && (isAuthRoute || isOnboarding)) return '/home';
      if (!isLoggedIn && !isAuthRoute && !isOnboarding) return '/login';
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
      GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen()),
      GoRoute(
          path: '/health-profile',
          builder: (context, state) => const HealthProfileScreen()),
      GoRoute(
          path: '/health-history',
          builder: (context, state) => const HealthHistoryScreen()),
      GoRoute(
          path: '/medical-documents',
          builder: (context, state) => const MedicalDocumentsScreen()),
      GoRoute(
          path: '/history',
          builder: (context, state) => const ScanHistoryScreen()),
      GoRoute(
        path: '/inventory/:id',
        builder: (context, state) {
            final item = state.extra as InventoryItem;
            return InventoryDetailScreen(item: item);
        },),
      GoRoute(
          path: '/food-intake',
          builder: (context, state) => const FoodIntakeScreen()),
      GoRoute(
          path: '/weekly-report',
          builder: (context, state) => const WeeklyReportScreen()),
    ],
  );
});