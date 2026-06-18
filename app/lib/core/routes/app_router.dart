import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/main_layout_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_summary_screen.dart';
import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../features/expenses/presentation/screens/expense_form_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/backup/presentation/screens/backup_screen.dart';
import '../../features/sms_parser/presentation/screens/sms_drafts_screen.dart';

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: AuthRefreshListenable(ref),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/backup',
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: '/sms-drafts',
        builder: (context, state) => const SmsDraftsScreen(),
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
                path: '/budgets',
                builder: (context, state) => const BudgetsScreen(),
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
      final loggingIn = state.matchedLocation == '/login';

      if (status == AuthStatus.loading) {
        return null;
      }

      if (status == AuthStatus.unauthenticated) {
        return loggingIn ? null : '/login';
      }

      if (status == AuthStatus.authenticated) {
        return loggingIn ? '/dashboard' : null;
      }

      return null;
    },
  );
});
