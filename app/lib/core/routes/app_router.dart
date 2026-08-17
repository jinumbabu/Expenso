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
import '../../features/dashboard/presentation/screens/notifications_screen.dart';
import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../features/expenses/presentation/screens/expense_form_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/backup/presentation/screens/backup_screen.dart';
import '../../features/backup/presentation/screens/conflict_resolution_screen.dart';
import '../../features/backup/presentation/screens/diagnostics_screen.dart';
import '../../features/backup/presentation/screens/google_drive_diagnostics_screen.dart';
import '../../features/sms_parser/presentation/screens/sms_drafts_screen.dart';
import '../../features/sms_parser/presentation/screens/developer_test_screen.dart';
import '../../features/advisor/presentation/screens/advisor_screen.dart';
import '../../features/dashboard/presentation/screens/privacy_settings_screen.dart';
import '../../features/dashboard/presentation/screens/ai_settings_screen.dart';
import '../../features/dashboard/presentation/screens/quick_add_notepad_screen.dart';
import '../../features/dashboard/presentation/screens/net_worth_detail_screen.dart';
import '../../features/dashboard/presentation/screens/expense_breakdown_screen.dart';
import '../../features/auth/presentation/screens/biometric_lock_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';
import '../../features/expenses/presentation/screens/monthly_transaction_detail_screen.dart';
import '../../features/accounts/presentation/screens/accounts_screen.dart';
import '../../features/accounts/presentation/screens/account_detail_screen.dart';
import '../../features/accounts/presentation/screens/credit_card_detail_screen.dart';
import '../../features/accounts/presentation/screens/account_ledger_credit_card_detail_screen.dart';
import '../../features/expenses/presentation/screens/bills_management_screen.dart';
import '../../features/expenses/presentation/screens/bill_detail_screen.dart';

import '../../features/chat/presentation/screens/help_screen.dart';
import '../../features/chat/presentation/screens/api_manager_screen.dart';

final isSplashCompleteProvider = StateProvider<bool>((ref) => false);

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(isUnlockedProvider, (_, __) => notifyListeners());
    ref.listen(isSplashCompleteProvider, (_, __) => notifyListeners());
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
        path: '/bills',
        builder: (context, state) => const BillsManagementScreen(),
      ),
      GoRoute(
        path: '/bills/:id',
        builder: (context, state) => BillDetailScreen(
          billId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: '/credit-card-detail',
        builder: (context, state) {
          final cardId = state.uri.queryParameters['cardId'];
          return CreditCardDetailScreen(initialCardId: cardId);
        },
      ),
      GoRoute(
        path: '/accounts/:id',
        builder: (context, state) => AccountDetailScreen(
          accountId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/accounts/credit-card/:id',
        builder: (context, state) => AccountLedgerCreditCardDetailScreen(
          accountId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/backup',
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: '/diagnostics',
        builder: (context, state) => const DiagnosticsScreen(),
      ),
      GoRoute(
        path: '/drive-diagnostics',
        builder: (context, state) => const GoogleDriveDiagnosticsScreen(),
      ),
      GoRoute(
        path: '/sms-drafts',
        builder: (context, state) => const SmsDraftsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/developer-tools',
        builder: (context, state) => const DeveloperTestScreen(),
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
        path: '/ai-settings',
        builder: (context, state) => const AiSettingsScreen(),
      ),
      GoRoute(
        path: '/chat-help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/api-manager',
        builder: (context, state) => const ApiManagerScreen(),
      ),
      GoRoute(
        path: '/quick-add-notepad',
        builder: (context, state) => const QuickAddNotepadScreen(),
      ),
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: '/monthly-transactions/:type',
        builder: (context, state) => MonthlyTransactionDetailScreen(
          type: state.pathParameters['type'] ?? 'expense',
        ),
      ),
      GoRoute(
        path: '/net-worth-detail',
        builder: (context, state) => const NetWorthDetailScreen(),
      ),
      GoRoute(
        path: '/expense-breakdown',
        builder: (context, state) => const ExpenseBreakdownScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainLayoutScreen(
          child: DashboardSummaryScreen(),
        ),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => ExpenseFormScreen(
              draftId: state.uri.queryParameters['draftId'],
              initialType: state.uri.queryParameters['type'],
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
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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

      if (!ref.read(isSplashCompleteProvider)) {
        return '/splash';
      }

      if (status == AuthStatus.loading) {
        return isSplash ? null : '/splash';
      }

      if (status == AuthStatus.unauthenticated) {
        return (loggingIn || isPublic) ? null : '/login';
      }

      if (status == AuthStatus.authenticated) {
        final hasCompletedOnboarding = ref.read(onboardingCompletedProvider);
        if (!hasCompletedOnboarding) {
          return matched == '/onboarding' ? null : '/onboarding';
        }

        final isUnlocked = ref.read(isUnlockedProvider);
        if (!isUnlocked) {
          return isLockedScreen ? null : '/lock';
        }
        return (loggingIn || isLockedScreen || isSplash || matched == '/onboarding') ? '/dashboard' : null;
      }

      return null;
    },
  );
});
