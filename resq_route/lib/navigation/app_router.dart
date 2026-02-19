import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/auth/presentation/screens/verification_screen.dart';
import '../features/auth/presentation/screens/emergency_contacts_screen.dart';
import '../features/routes/presentation/screens/home_screen.dart';
import '../features/routes/presentation/screens/search_screen.dart';
import '../features/routes/presentation/screens/route_selection_screen.dart';
import '../features/monitoring/presentation/screens/active_journey_screen.dart';
import '../features/reporting/presentation/screens/journey_complete_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/flag_moderation_screen.dart';
import '../features/admin/presentation/screens/score_tuning_screen.dart';

/// App navigation using GoRouter.
/// Routes are added progressively as features are implemented.
class AppRouterConfig {
  AppRouterConfig._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // ── Splash ──
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth Routes (Phase 2) ──
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final phone = extra?['phone'] as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/verify-identity',
        name: 'verify-identity',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/emergency-contacts',
        name: 'emergency-contacts',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),

      // ── Phase 3: Home + Route Routes ──
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/route-selection',
        name: 'route-selection',
        builder: (context, state) => const RouteSelectionScreen(),
      ),

      // ── Phase 5: Journey Monitoring ──
      GoRoute(
        path: '/active-journey',
        name: 'active-journey',
        builder: (context, state) => const ActiveJourneyScreen(),
      ),
      // GoRoute(path: '/sos', ...),

      // ── Phase 7: Reporting ──
      GoRoute(
        path: '/journey-complete/:journeyId',
        name: 'journey-complete',
        builder: (context, state) => JourneyCompleteScreen(
          journeyId: state.pathParameters['journeyId']!,
        ),
      ),

      // ── Phase 8: Admin Dashboard ──
      GoRoute(
        path: '/admin',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/moderation',
        name: 'admin-moderation',
        builder: (context, state) => const FlagModerationScreen(),
      ),
      GoRoute(
        path: '/admin/score-tuning',
        name: 'admin-score-tuning',
        builder: (context, state) => const ScoreTuningScreen(),
      ),
    ],
  );
}
