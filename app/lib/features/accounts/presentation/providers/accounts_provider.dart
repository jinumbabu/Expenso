import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../../core/services/balance_engine.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../../../../core/services/ledger_agent.dart';
import '../../../../core/security/secure_storage_service.dart';

// Stream/State notifier for all accounts
final accountsProvider = StateNotifierProvider<AccountsNotifier, AsyncValue<List<Account>>>((ref) {
  final auth = ref.watch(authProvider);
  final db = ref.watch(databaseProvider);
  return AccountsNotifier(db: db, userId: auth.user?.id);
});

class AccountsNotifier extends StateNotifier<AsyncValue<List<Account>>> {
  final AppDatabase _db;
  final String? _userId;
  StreamSubscription<List<Account>>? _subscription;
  bool _isSeeding = false;

  AccountsNotifier({
    required AppDatabase db,
    required String? userId,
  }) : _db = db,
       _userId = userId,
       super(const AsyncValue.loading()) {
    _initStream();
  }

  void _initStream() {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    _subscription?.cancel();
    _subscription = (_db.select(_db.accounts)..where((t) => t.userId.equals(_userId!)))
        .watch()
        .listen((list) async {
          if (list.isEmpty) {
            if (!_isSeeding) {
              _isSeeding = true;
              try {
                await _seedDefaultAccounts();
              } catch (e, stack) {
                state = AsyncValue.error(e, stack);
              } finally {
                _isSeeding = false;
              }
            }
          } else {
            state = AsyncValue.data(list);
          }
        }, onError: (e, stack) {
          state = AsyncValue.error(e, stack);
        });
  }

  Future<void> loadAccounts() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      var list = await (_db.select(_db.accounts)..where((t) => t.userId.equals(_userId!))).get();
      if (list.isEmpty) {
        if (!_isSeeding) {
          _isSeeding = true;
          try {
            await _seedDefaultAccounts();
          } finally {
            _isSeeding = false;
          }
        }
        list = await (_db.select(_db.accounts)..where((t) => t.userId.equals(_userId!))).get();
      }
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _seedDefaultAccounts() async {
    if (_userId == null) return;
    final now = DateTime.now();

    final defaults = [
      Account(
        id: 'cash-$_userId',
        userId: _userId!,
        name: 'Cash Wallet',
        type: 'cash',
        balance: 0, // ₹0
        isDefault: true,
        createdAt: now,
        updatedAt: now,
        bankName: 'Cash',
        openingBalance: 0,
        currency: 'INR',
        colorTheme: '0xFF00E5FF',
        icon: 'account_balance_wallet',
        isActive: true,
        isEstimated: false,
      ),
      Account(
        id: 'sbi-$_userId',
        userId: _userId!,
        name: 'SBI Savings',
        type: 'savings',
        balance: 0, // ₹0
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        bankName: 'State Bank of India',
        openingBalance: 0,
        currency: 'INR',
        colorTheme: '0xFF0066FF',
        icon: 'account_balance',
        isActive: true,
        isEstimated: false,
      ),
      Account(
        id: 'gpay-$_userId',
        userId: _userId!,
        name: 'Google Pay Wallet',
        type: 'wallet',
        balance: 0, // ₹0
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        bankName: 'Google Pay',
        openingBalance: 0,
        currency: 'INR',
        colorTheme: '0xFFFFB703',
        icon: 'account_balance_wallet',
        isActive: true,
        isEstimated: false,
      ),
      Account(
        id: 'hdfc-cc-$_userId',
        userId: _userId!,
        name: 'HDFC Credit Card',
        type: 'credit_card',
        balance: 0, // ₹0 outstanding (balance is -outstandingBalance)
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        bankName: 'HDFC Bank',
        openingBalance: 0,
        currency: 'INR',
        colorTheme: '0xFFFF3B30',
        icon: 'credit_card',
        isActive: true,
        creditLimit: 10000000, // ₹100,000 limit
        availableCredit: 10000000,
        outstandingBalance: 0,
        statementDate: 15,
        paymentDueDate: 5,
        autoPay: false,
        paymentStatus: 'paid',
        isEstimated: false,
      ),
    ];

    for (var acc in defaults) {
      await _db.into(_db.accounts).insert(acc);
    }
  }

  Future<void> addAccount(AccountsCompanion companion) async {
    try {
      state = const AsyncValue.loading();
      await _db.into(_db.accounts).insert(companion);
      await BalanceEngine(_db).recalculateAllBalances();
      await loadAccounts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editAccount(Account account) async {
    try {
      state = const AsyncValue.loading();
      await _db.update(_db.accounts).replace(account);
      await BalanceEngine(_db).recalculateAllBalances();
      await loadAccounts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeAccount(String id) async {
    try {
      state = const AsyncValue.loading();
      await (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();
      await loadAccounts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> acceptImportedBalance(String accountId) async {
    try {
      state = const AsyncValue.loading();
      await LedgerAgent(_db).acceptImportedBalance(accountId);
      await loadAccounts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> keepVerifiedBalance(String accountId) async {
    try {
      state = const AsyncValue.loading();
      await LedgerAgent(_db).keepVerifiedBalance(accountId);
      await loadAccounts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> dismissDiscrepancy(String accountId) async {
    try {
      state = const AsyncValue.loading();
      await LedgerAgent(_db).dismissDiscrepancy(accountId);
      await loadAccounts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createAdjustmentEntry(String accountId, String userId, int amountInCents) async {
    try {
      state = const AsyncValue.loading();
      await LedgerAgent(_db).createAdjustmentEntry(accountId, userId, amountInCents);
      await loadAccounts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> adjustBalanceManually(String accountId, int newBalanceInCents, bool createEntry, String userId) async {
    try {
      state = const AsyncValue.loading();
      final account = await (_db.select(_db.accounts)..where((a) => a.id.equals(accountId))).getSingleOrNull();
      if (account != null) {
        if (createEntry) {
          final current = account.type == 'credit_card' ? (account.outstandingBalance ?? 0) : account.balance;
          final diff = newBalanceInCents - current;
          if (diff != 0) {
            // For bank/savings: positive diff means we received income, negative means expense.
            // For credit card: manual adjustments are treated accordingly
            await LedgerAgent(_db).createAdjustmentEntry(accountId, userId, diff);
          }
        } else {
          // Simply update verifiedBalance and verifiedAt
          final updated = account.copyWith(
            verifiedBalance: Value(newBalanceInCents),
            verifiedAt: Value(DateTime.now()),
            hasMismatch: const Value(false),
            mismatchExpected: const Value(null),
            mismatchImported: const Value(null),
            updatedAt: DateTime.now(),
          );
          await _db.accountDao.updateAccount(updated);
          await BalanceEngine(_db).recalculateAllBalances(accountId: accountId);
        }
      }
      await loadAccounts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateAccountSortOrder(List<Account> reorderedList) async {
    try {
      state = const AsyncValue.loading();
      await _db.transaction(() async {
        for (int i = 0; i < reorderedList.length; i++) {
          final acc = reorderedList[i];
          await (_db.update(_db.accounts)..where((t) => t.id.equals(acc.id)))
              .write(AccountsCompanion(sortOrder: Value(i)));
        }
      });
      await loadAccounts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class AccountSummary {
  final int totalAssets;
  final int totalLiabilities;
  final int netAssets;
  final int cashBalance;
  final int bankBalance;
  final int walletBalance;
  final int ccOutstanding;
  final int investmentBalance;
  final int loanOutstanding;

  AccountSummary({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netAssets,
    required this.cashBalance,
    required this.bankBalance,
    required this.walletBalance,
    required this.ccOutstanding,
    required this.investmentBalance,
    required this.loanOutstanding,
  });
}

final recalculatedAccountsProvider = Provider<AsyncValue<List<Account>>>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final txsAsync = ref.watch(expenseListNotifierProvider);

  return accountsAsync.when(
    data: (accounts) {
      return txsAsync.when(
        data: (txs) {
          print('RECALCULATED_ACCOUNTS_PROVIDER: accountsCount=${accounts.length}, transactionsCount=${txs.length}');
          for (var tx in txs) {
            print('  TX: id=${tx.id}, amount=${tx.amount}, accountId=${tx.accountId}, referenceNumber=${tx.referenceNumber}, type=${tx.type}, deletedAt=${tx.deletedAt}');
          }
          final recalculatedList = accounts.map((acc) {
            final calculated = FinancialCalculationService.calculateSingleAccountBalance(acc, txs);
            print('  Account "${acc.name}" (${acc.id}): Stored Balance = ${acc.balance}, Stored CC Outstanding = ${acc.outstandingBalance}, Recalculated Balance = ${calculated.balance}, Recalculated CC Outstanding = ${calculated.outstandingBalance}');
            return calculated;
          }).toList();
          return AsyncValue.data(recalculatedList);
        },
        loading: () {
          print('RECALCULATED_ACCOUNTS_PROVIDER: txs is loading');
          return const AsyncValue.loading();
        },
        error: (e, st) {
          print('RECALCULATED_ACCOUNTS_PROVIDER: txs error: $e');
          return AsyncValue.error(e, st);
        },
      );
    },
    loading: () {
      print('RECALCULATED_ACCOUNTS_PROVIDER: accounts is loading');
      return const AsyncValue.loading();
    },
    error: (e, st) {
      print('RECALCULATED_ACCOUNTS_PROVIDER: accounts error: $e');
      return AsyncValue.error(e, st);
    },
  );
});

final accountSummaryProvider = Provider<AsyncValue<AccountSummary>>((ref) {
  final accountsAsync = ref.watch(recalculatedAccountsProvider);
  return accountsAsync.whenData((list) {
    final centralSummary = FinancialCalculationService.calculateAccountSummary(list);
    return AccountSummary(
      totalAssets: centralSummary.totalAssets,
      totalLiabilities: centralSummary.totalLiabilities,
      netAssets: centralSummary.netAssets,
      cashBalance: centralSummary.cashBalance,
      bankBalance: centralSummary.bankBalance,
      walletBalance: centralSummary.walletBalance,
      ccOutstanding: centralSummary.ccOutstanding,
      investmentBalance: centralSummary.investmentBalance,
      loanOutstanding: centralSummary.loanOutstanding,
    );
  });
});

final accountTransactionsProvider = Provider.family<AsyncValue<List<Transaction>>, String>((ref, accountId) {
  final txsAsync = ref.watch(expenseListNotifierProvider);
  return txsAsync.whenData((list) {
    return list.where((tx) => tx.accountId == accountId || (tx.type == 'transfer' && tx.referenceNumber == accountId)).toList();
  });
});

final accountParsedSmsProvider = StreamProvider.family<List<ParsedSmsEntry>, String>((ref, accountId) {
  final db = ref.watch(databaseProvider);
  final accountsAsync = ref.watch(accountsProvider);
  
  return accountsAsync.when(
    data: (accounts) {
      final account = accounts.firstWhere((a) => a.id == accountId, orElse: () => null as dynamic);
      if (account == null || account.last4Digits == null) {
        return const Stream.empty();
      }
      
      return (db.select(db.parsedSms)
        ..where((t) => t.accountLast4.equals(account.last4Digits!))
        ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
        .watch();
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

final accountSortProvider = StateNotifierProvider<AccountSortNotifier, String>((ref) {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  return AccountSortNotifier(userId);
});

class AccountSortNotifier extends StateNotifier<String> {
  final String? _userId;
  final SecureStorageService _storage = SecureStorageService();

  AccountSortNotifier(this._userId) : super('updated') {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final key = (_userId != null && _userId!.isNotEmpty) ? _userId! : 'default_user';
    final saved = await _storage.getAccountSortBy(key);
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    } else {
      state = 'updated';
    }
  }

  Future<void> setSortBy(String sortBy) async {
    state = sortBy;
    final key = (_userId != null && _userId!.isNotEmpty) ? _userId! : 'default_user';
    await _storage.saveAccountSortBy(key, sortBy);
  }
}

