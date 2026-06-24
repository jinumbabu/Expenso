import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/terms_screen.dart';
import '../../features/auth/presentation/screens/privacy_screen.dart';
import '../../features/dashboard/presentation/screens/main_layout_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_summary_screen.dart';
import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../features/expenses/presentation/screens/expense_form_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/backup/presentation/screens/backup_screen.dart';
import '../../features/backup/presentation/screens/conflict_resolution_screen.dart';
import '../../features/sms_parser/presentation/screens/sms_drafts_screen.dart';
import '../../features/advisor/presentation/screens/advisor_screen.dart';
import '../../features/dashboard/presentation/screens/privacy_settings_screen.dart';
import '../../features/auth/presentation/screens/biometric_lock_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';

final isSplashCompleteProvider = StateProvider<bool>((ref) => false);

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(isUnlockedProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: AuthRefreshListenable(ref),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => const BiometricLockScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: '/backup',
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: '/sms-drafts',
        builder: (context, state) => const SmsDraftsScreen(),
      ),
      GoRoute(
        path: '/conflict-resolution',
        builder: (context, state) => const ConflictResolutionScreen(),
      ),
      GoRoute(
        path: '/advisor',
        builder: (context, state) => const AdvisorScreen(),
      ),
      GoRoute(
        path: '/privacy-settings',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const BudgetsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayoutScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardSummaryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const ExpensesScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => ExpenseFormScreen(
                      draftId: state.uri.queryParameters['draftId'],
                    ),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) => ExpenseFormScreen(
                      transactionId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final currentAuth = ref.read(authProvider);
      final status = currentAuth.status;
      final matched = state.matchedLocation;
      final loggingIn = matched == '/login';
      final isLockedScreen = matched == '/lock';
      final isSplash = matched == '/splash';
      final isPublic = matched == '/terms' || matched == '/privacy';

      if (!isSplash && !ref.read(isSplashCompleteProvider)) {
        return '/splash';
      }

      if (isSplash) {
        return null;
      }

      if (status == AuthStatus.loading) {
        return null;
      }

      if (status == AuthStatus.unauthenticated) {
        return (loggingIn || isPublic) ? null : '/login';
      }

      if (status == AuthStatus.authenticated) {
        final isUnlocked = ref.read(isUnlockedProvider);
        if (!isUnlocked) {
          return isLockedScreen ? null : '/lock';
        }
        return (loggingIn || isLockedScreen) ? '/dashboard' : null;
      }

      return null;
    },
  );
});
