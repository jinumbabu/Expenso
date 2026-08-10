import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/database/app_database.dart';
import 'package:app/core/security/audit_logger.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/core/services/financial_calculation_service.dart';

void main() {
  late AppDatabase database;
  const userId = 'user_recalc_test';

  setUp(() async {
    database = AppDatabase.connect(NativeDatabase.memory());
    
    // Seed test user
    await database.customStatement(
      'INSERT INTO users (id, google_id, email, display_name, created_at, updated_at) '
      'VALUES (?, ?, "recalc@test.com", "Recalc User", 1719532800, 1719532800);',
      [userId, userId],
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('Diagnostic User Balance Calculation Case', () async {
    // Create HDFC Account with ₹0 opening balance
    final hdfcAccount = Account(
      id: 'hdfc-savings',
      userId: userId,
      name: 'HDFC Account',
      type: 'savings',
      balance: 0,
      isDefault: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      bankName: 'HDFC Bank',
      openingBalance: 0,
      currency: 'INR',
      colorTheme: '0xFF0066FF',
      icon: 'account_balance',
      isActive: true,
      isEstimated: false,
    );

    await database.into(database.accounts).insert(hdfcAccount);

    // Seed transactions
    // 1. Income: +₹38,223.00
    final t1 = Transaction(
      id: const Uuid().v4(),
      userId: userId,
      accountId: hdfcAccount.id,
      type: 'income',
      amount: 3822300, // ₹38,223.00 in cents
      currency: 'INR',
      description: 'Income test',
      merchant: 'Employer',
      date: DateTime.now(),
      source: 'manual',
      isRecurring: false,
      syncStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 2. Expenses: -₹160.00, -₹70.00, -₹3,350.77, -₹18,219.23
    final expenseAmounts = [16000, 7000, 335077, 1821923]; // in cents
    final List<Transaction> expenses = [];
    for (int i = 0; i < expenseAmounts.length; i++) {
      expenses.add(Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: hdfcAccount.id,
        type: 'expense',
        amount: expenseAmounts[i],
        currency: 'INR',
        description: 'Expense test $i',
        merchant: 'Merchant $i',
        date: DateTime.now(),
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    final allTxs = [t1, ...expenses];
    for (var tx in allTxs) {
      await database.into(database.transactions).insert(tx);
    }

    print('--- EVALUATING DIRECT CALCULATION ---');
    final calculatedHdfc = FinancialCalculationService.calculateSingleAccountBalance(hdfcAccount, allTxs);
    print('Direct Calculated HDFC Balance: ${calculatedHdfc.balance}');

    print('--- EVALUATING PROVIDER CALCULATION ---');
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        authProvider.overrideWith((ref) => AuthNotifierMock(userId, database)),
      ],
    );

    // Wait for streams
    await Future.delayed(const Duration(milliseconds: 100));

    final accountsVal = container.read(recalculatedAccountsProvider);
    final accounts = accountsVal.value ?? [];
    print('Provider Accounts List Length: ${accounts.length}');
    for (var acc in accounts) {
      print('Provider Account "${acc.name}" balance: ${acc.balance}');
    }
  });
}

class AuthNotifierMock extends AuthNotifier {
  AuthNotifierMock(String userId, AppDatabase db)
      : super(FakeAuthRepository(), AuditLogger(db), FakeRef()) {
    state = AuthState.authenticated(User(
      id: userId,
      googleId: userId,
      email: 'recalc@test.com',
      displayName: 'Recalc User',
      currency: 'INR',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> checkSession() async {}
}

class FakeRef extends Fake implements Ref {}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<User?> getCurrentSessionUser() async => null;
  @override
  Future<User?> getUserById(String id) async => null;
  @override
  Future<User?> getUserByEmail(String email) async => null;
  @override
  Future<void> createUser(User user) async {}
  @override
  Future<void> updateUser(User user) async {}
  @override
  Future<void> deleteUser(String id) async {}
  @override
  Future<User?> loginWithGoogle(String googleToken) async => null;
  @override
  Future<User?> loginOffline({String? email, String? displayName, String? googleId}) async => null;
  @override
  Future<void> logout() async {}
  @override
  Future<bool> isSessionValid() async => true;
}
