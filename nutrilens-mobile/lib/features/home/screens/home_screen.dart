import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriLens 🥗'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text(
              'Bienvenue, ${user?.username ?? ''} !',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('BMI : ${user?.profile.bmi ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Objectif : ${user?.profile.goal ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }
}