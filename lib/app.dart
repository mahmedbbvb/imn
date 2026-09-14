import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/utils/app_logger.dart';
import 'shell/app_shell.dart';
import 'features/identity/onboarding_screen.dart';

/// Root widget that checks if identity exists and routes accordingly.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityInit = ref.watch(identityInitProvider);

    return identityInit.when(
      loading: () => const _SplashScreen(),
      error: (e, st) {
        appLogger.e('Identity init error', error: e, stackTrace: st);
        return const _ErrorScreen();
      },
      data: (_) {
        final identity = ref.read(identityServiceProvider);
        if (identity.deviceId.isEmpty) {
          return const OnboardingScreen();
        }
        return const AppShell();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock_rounded,
                  size: 44, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text('Imn',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Encrypted P2P Messenger',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Initialization Error',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Failed to initialize app security. Please reinstall.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
