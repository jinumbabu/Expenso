import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/database/app_database.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/features/expenses/domain/usecases/get_transactions_usecase.dart';
import 'package:app/features/expenses/domain/usecases/create_transaction_usecase.dart';
import 'package:app/features/expenses/domain/usecases/update_transaction_usecase.dart';
import 'package:app/features/expenses/domain/usecases/delete_transaction_usecase.dart';
import 'package:app/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:app/core/services/financial_calculation_service.dart' hide AccountSummary;
import 'package:app/features/dashboard/presentation/screens/dashboard_summary_screen.dart';
import 'package:app/features/dashboard/presentation/providers/privacy_provider.dart';
import 'package:app/shared/widgets/reusable_net_worth_ring.dart';
import 'package:app/features/sms_parser/presentation/providers/sms_parser_provider.dart';
import 'package:app/features/advisor/presentation/providers/advisor_provider.dart';
import 'package:app/features/backup/presentation/providers/backup_provider.dart';
import 'package:app/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:app/core/services/notification_service.dart';
import 'package:app/core/security/audit_logger.dart';
import 'package:app/core/sync/backup_service.dart';
import 'package:app/core/services/sms_agent.dart';
import 'package:app/core/services/ledger_agent.dart';
import 'package:app/core/security/secure_storage_service.dart';
import 'package:app/core/services/voice_service.dart';

class FakeDatabase extends Fake implements AppDatabase {}
class FakeAuthRepository extends Fake implements AuthRepository {}
class FakeAuditLogger extends Fake implements AuditLogger {}
class FakeGetTransactionsUseCase extends Fake implements GetTransactionsUseCase {}
class FakeCreateTransactionUseCase extends Fake implements CreateTransactionUseCase {}
class FakeUpdateTransactionUseCase extends Fake implements UpdateTransactionUseCase {}
class FakeDeleteTransactionUseCase extends Fake implements DeleteTransactionUseCase {}

class FakeRef extends Fake implements Ref {
  @override
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    return FakeProviderSubscription<T>();
  }
}

class FakeProviderSubscription<T> extends Fake implements ProviderSubscription<T> {
  @override
  void close() {}
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(User user) : super(FakeAuthRepository(), FakeAuditLogger(), FakeRef()) {
    state = AuthState.authenticated(user);
  }

  @override
  Future<void> checkSession() async {}
}

class MockExpenseListNotifier extends ExpenseListNotifier {
  MockExpenseListNotifier(List<Transaction> initialData)
      : super(
          getTransactions: FakeGetTransactionsUseCase(),
          createTransaction: FakeCreateTransactionUseCase(),
          updateTransaction: FakeUpdateTransactionUseCase(),
          deleteTransaction: FakeDeleteTransactionUseCase(),
          userId: 'user1',
          ref: FakeRef(),
        ) {
    state = AsyncValue.data(initialData);
  }

  @override
  Future<void> loadTransactions() async {}
}

class FakeBackupService extends Fake implements BackupService {}

class FakeBackupNotifier extends BackupNotifier {
  FakeBackupNotifier() : super(FakeBackupService(), FakeAuditLogger(), FakeRef());

  @override
  Future<void> loadBackupInfo() async {}
  @override
  Future<void> checkAndRunScheduledBackup() async {}
}

class FakeSmsAgent extends Fake implements SmsAgent {}
class FakeLedgerAgent extends Fake implements LedgerAgent {}
class FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<void> sendProactiveAlert(
    String userId, {
    required String title,
    required String body,
    String priority = 'normal',
  }) async {}
}
class FakeSecureStorageService extends Fake implements SecureStorageService {
  @override
  Future<bool> getAutoImportEnabled() async => true;
  @override
  Future<DateTime?> getLastPermissionRequestTime() async => null;
  @override
  Future<DateTime?> getLastSmsSyncTime() async => null;
  @override
  Future<bool> getHasRequestedSmsPermission() async => true;
}

class FakeSmsScannerNotifier extends SmsScannerNotifier {
  FakeSmsScannerNotifier() : super(
    db: FakeDatabase(),
    userId: 'user1',
    smsAgent: FakeSmsAgent(),
    ledgerAgent: FakeLedgerAgent(),
    notificationService: FakeNotificationService(),
    secureStorage: FakeSecureStorageService(),
    ref: FakeRef(),
  );

  @override
  Future<void> checkPermissions() async {}
}

class FakeSpeechToText extends Fake implements SpeechToText {}

class FakeVoiceService extends VoiceService {
  FakeVoiceService() : super(speech: FakeSpeechToText());
  
  @override
  Future<bool> initialize() async => true;
}

class FakeAdvisorNotifier extends AdvisorNotifier {
  FakeAdvisorNotifier() : super(FakeRef());

  @override
  Future<void> calculateFinancialOverview() async {}

  @override
  Future<void> loadInsights() async {}
}

class FakePrivacyModeNotifier extends PrivacyModeNotifier {
  FakePrivacyModeNotifier() : super(FakeRef());

  @override
  Future<void> toggle() async {}
}

void main() {
  group('DashboardSummaryScreen Net Worth Card Widget Tests', () {
    late User testUser;
    late MockAuthNotifier mockAuth;
    late List<Transaction> mockTxs;
    final now = DateTime.now();

    setUp(() {
      testUser = User(
        id: 'user1',
        googleId: 'google1',
        email: 'test@expenso.ai',
        displayName: 'Test User',
        currency: 'INR',
        createdAt: now,
        updatedAt: now,
      );
      mockAuth = MockAuthNotifier(testUser);

      mockTxs = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'expense',
          amount: 8300, // ₹83.00
          currency: 'INR',
          merchant: 'McDonalds',
          description: 'Lunch',
          date: now,
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    testWidgets('Renders Net Worth card with compact Expenses/Remaining ring and handles tap navigation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeNotifier = MockExpenseListNotifier(mockTxs);
      final fakeBackup = FakeBackupNotifier();
      final fakeSms = FakeSmsScannerNotifier();
      final fakeVoice = FakeVoiceService();
      final fakeAdvisor = FakeAdvisorNotifier();
      final fakePrivacy = FakePrivacyModeNotifier();

      // Configure a test router to verify GoRouter navigation targets
      final testRouter = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const Scaffold(
              body: DashboardSummaryScreen(),
            ),
          ),
          GoRoute(
            path: '/expense-breakdown',
            builder: (context, state) => const Scaffold(
              body: Text('Expense Breakdown Screen'),
            ),
          ),
          GoRoute(
            path: '/net-worth-detail',
            builder: (context, state) => const Scaffold(
              body: Text('Net Worth Detail Screen'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(FakeDatabase()),
            authProvider.overrideWith((ref) => mockAuth),
            expenseListNotifierProvider.overrideWith((ref) => fakeNotifier),
            categoriesProvider.overrideWith((ref) => []),
            paymentMethodsProvider.overrideWith((ref) => []),
            recalculatedAccountsProvider.overrideWithValue(const AsyncValue.data([])),
            accountSummaryProvider.overrideWithValue(
              AsyncValue.data(
                AccountSummary(
                  totalAssets: 10000,
                  totalLiabilities: 1000,
                  netAssets: 9000,
                  cashBalance: 0,
                  bankBalance: 10000,
                  walletBalance: 0,
                  ccOutstanding: 1000,
                  investmentBalance: 0,
                  loanOutstanding: 0,
                ),
              ),
            ),
            dashboardFinancialDataProvider.overrideWithValue(
              const FinancialData(
                openingBalance: 1000,
                monthlyIncome: 0,
                monthlyExpenses: 8300, // ₹83.00
                netWorth: 9000,
              ),
            ),
            dismissedOpeningBalancePromptsProvider.overrideWith((ref) => {}),
            hasCheckedBackupRestoreProvider.overrideWith((ref) => true),
            privacyModeProvider.overrideWith((ref) => fakePrivacy),
            budgetStatusProviderList.overrideWithValue(const AsyncValue.data([])),
            notificationsStreamProvider.overrideWith((ref) => const Stream.empty()),
            transactionDraftsStreamProvider.overrideWith((ref) => const Stream.empty()),
            databaseSubscriptionsStreamProvider.overrideWith((ref) => const Stream.empty()),
            databasePendingBillsStreamProvider.overrideWith((ref) => const Stream.empty()),
            smsScannerProvider.overrideWith((ref) => fakeSms),
            voiceServiceProvider.overrideWith((ref) => fakeVoice),
            advisorProvider.overrideWith((ref) => fakeAdvisor),
            backupNotifierProvider.overrideWith((ref) => fakeBackup),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      // Wait for layout pump
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify card title
      expect(find.text('SAVINGS'), findsOneWidget);

      // 2. Verify shared ReusableNetWorthRing is rendered inside Net Worth card
      expect(find.byType(ReusableNetWorthRing), findsOneWidget);

      // 3. Verify Expenses and Remaining labels/percentages are shown
      expect(find.text('Expenses'), findsWidgets);
      expect(find.text('Remaining'), findsWidgets);

      // Verify the calculated percentages
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      // 4. Tap the ReusableNetWorthRing and verify navigation to Expense Breakdown Screen
      await tester.tap(find.byType(ReusableNetWorthRing));
      await tester.pumpAndSettle();
      expect(find.text('Expense Breakdown Screen'), findsOneWidget);

      // Go back to dashboard
      testRouter.go('/dashboard');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('SAVINGS'), findsOneWidget);

      // 5. Tap the Expenses title and verify navigation
      await tester.tap(find.text('Expenses').first);
      await tester.pumpAndSettle();
      expect(find.text('Expense Breakdown Screen'), findsOneWidget);

      // Go back
      testRouter.go('/dashboard');
      await tester.pump(const Duration(milliseconds: 500));

      // 6. Tap the Remaining percentage and verify navigation
      await tester.tap(find.text('0%'));
      await tester.pumpAndSettle();
      expect(find.text('Expense Breakdown Screen'), findsOneWidget);
    });
  });
}
