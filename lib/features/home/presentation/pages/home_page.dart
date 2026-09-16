import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rivalfit/features/auth/presentation/widgets/brand_mark.dart';
import 'package:rivalfit/features/auth/presentation/widgets/glass_background.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text('RivalFit'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).signOut();
                    },
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BrandMark(size: 80),
                      const SizedBox(height: 24),
                      const Text(
                        'Bienvenido!',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (authState.user != null)
                        Text(
                          authState.user!.displayName,
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 16,
                          ),
                        ),
                      const SizedBox(height: 32),
                      const Text(
                        'Proximamente: Rankings, Sesiones, Ligas...',
                        style: TextStyle(
                          color: AppColors.textPlaceholder,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
