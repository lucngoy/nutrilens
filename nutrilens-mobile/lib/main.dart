import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(
    onTap: (payload) {
      // Navigate to inventory on notification tap
      if (payload == 'inventory' || payload == null) {
        // Router will handle navigation once app is ready
      }
    },
  );
  runApp(const ProviderScope(child: NutriLensApp()));
}

class NutriLensApp extends ConsumerWidget {
  const NutriLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'NutriLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}