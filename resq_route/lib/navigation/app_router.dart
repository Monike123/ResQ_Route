import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App navigation using GoRouter.
/// Routes are added progressively as features are implemented.
class AppRouterConfig {
  AppRouterConfig._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const _PlaceholderHome(),
      ),
      // ── Auth Routes (Phase 2) ──
      // GoRoute(path: '/login', ...),
      // GoRoute(path: '/signup', ...),
      // GoRoute(path: '/verify', ...),

      // ── Route Routes (Phase 3) ──
      // GoRoute(path: '/search', ...),
      // GoRoute(path: '/route-results', ...),

      // ── Journey Routes (Phase 5) ──
      // GoRoute(path: '/journey', ...),
      // GoRoute(path: '/sos', ...),
    ],
  );
}

/// Temporary placeholder home screen.
/// Will be replaced with actual home in Phase 2+.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'ResQ Route',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Setup Complete ✅',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 32),
            Text(
              'Phase 1 — Foundation Ready',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
