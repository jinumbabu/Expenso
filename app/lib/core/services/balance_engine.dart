import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'financial_calculation_service.dart';

class BalanceEngine {
  final AppDatabase _db;

  BalanceEngine(this._db);

  int getBalanceDelta(Transaction tx, String accountType) {
    final amount = tx.amount.toInt();
    final accountId = tx.accountId ?? '';
    final isCredit = FinancialCalculationService.isCredit(tx, accountId);
    final isDebit = FinancialCalculationService.isDebit(tx, accountId);

    if (accountType == 'credit_card') {
      if (isCredit) {
        return -amount; // Reduces outstanding balance
      } else if (isDebit) {
        return amount; // Increases outstanding balance
      }
    } else {
      if (isCredit) {
        return amount; // Increases bank/cash balance
      } else if (isDebit) {
        return -amount; // Decreases bank/cash balance
      }
    }
    return 0;
  }

  /// Reconciles an account balance when a new transaction is added.
  Future<void> reconcileOnAdd(Transaction tx) async {
    if (tx.accountId != null) {
      await recalculateAllBalances(accountId: tx.accountId);
    }
    if (tx.referenceNumber != null) {
      await recalculateAllBalances(accountId: tx.referenceNumber);
    }
  }

  /// Reconciles an account balance when a transaction is deleted.
  Future<void> reconcileOnDelete(Transaction tx) async {
    if (tx.accountId != null) {
      await recalculateAllBalances(accountId: tx.accountId);
    }
    if (tx.referenceNumber != null) {
      await recalculateAllBalances(accountId: tx.referenceNumber);
    }
  }

  /// Reconciles an account balance when a transaction is edited.
  Future<void> reconcileOnEdit(Transaction oldTx, Transaction newTx) async {
    final affectedAccounts = <String>{};
    if (oldTx.accountId != null) affectedAccounts.add(oldTx.accountId!);
    if (oldTx.referenceNumber != null) affectedAccounts.add(oldTx.referenceNumber!);
    if (newTx.accountId != null) affectedAccounts.add(newTx.accountId!);
    if (newTx.referenceNumber != null) affectedAccounts.add(newTx.referenceNumber!);

    for (var accId in affectedAccounts) {
      await recalculateAllBalances(accountId: accId);
    }
  }

  /// Recalculates all or specific account balances in the database by summing up all transaction deltas.
  Future<void> recalculateAllBalances({String? accountId}) async {
    final query = _db.select(_db.accounts);
    if (accountId != null) {
      query.where((a) => a.id.equals(accountId));
    }
    final accounts = await query.get();

    for (var acc in accounts) {
      Account account = acc;

      // Self-heal accounts with null openingBalance to ensure baseline integrity
      if (account.openingBalance == null && account.isEstimated != true) {
        final initialBal = account.type == 'credit_card' 
            ? (account.outstandingBalance ?? 0) 
            : account.balance;
        account = account.copyWith(openingBalance: Value(initialBal));
        await _db.accountDao.updateAccount(account);
      }

      final txs = await (_db.select(_db.transactions)
        ..where((t) => (t.accountId.equals(account.id) | t.referenceNumber.equals(account.id)) & t.deletedAt.isNull())
      ).get();

      final updated = FinancialCalculationService.calculateSingleAccountBalance(account, txs);
      // Include updatedAt timestamp
      final updatedWithTime = updated.copyWith(updatedAt: DateTime.now());
      await _db.accountDao.updateAccount(updatedWithTime);
    }
  }

  Future<void> validateAndSelfHeal() async {
    final query = _db.select(_db.accounts);
    final accounts = await query.get();
    final logFile = File('c:/Users/jinum/Expenso/balance_discrepancy_logs.txt');

    try {
      if (!logFile.existsSync()) {
        logFile.createSync(recursive: true);
      }
    } catch (_) {}

    final timestamp = DateTime.now().toIso8601String();
    
    for (var acc in accounts) {
      final txs = await (_db.select(_db.transactions)
        ..where((t) => (t.accountId.equals(acc.id) | t.referenceNumber.equals(acc.id)) & t.deletedAt.isNull())
      ).get();

      final updatedAcc = FinancialCalculationService.calculateSingleAccountBalance(acc, txs);

      int expectedBalance;
      int cachedBalance;
      if (acc.type == 'credit_card') {
        expectedBalance = updatedAcc.outstandingBalance ?? 0;
        cachedBalance = acc.outstandingBalance ?? 0;
      } else {
        expectedBalance = updatedAcc.balance;
        cachedBalance = acc.balance;
      }

      if (expectedBalance != cachedBalance) {
        // Discrepancy detected!
        final logMsg = '[$timestamp] DISCREPANCY: Account "${acc.name}" (${acc.id}) has cached balance ₹${cachedBalance / 100.0}, but transaction history expects ₹${expectedBalance / 100.0}. Difference: ₹${(expectedBalance - cachedBalance).abs() / 100.0}.\n';
        try {
          logFile.writeAsStringSync(logMsg, mode: FileMode.append);
        } catch (_) {}

        // Flag the account with the mismatch
        final flaggedAcc = acc.copyWith(
          hasMismatch: const Value(true),
          mismatchExpected: Value(expectedBalance),
          mismatchImported: Value(cachedBalance),
          updatedAt: DateTime.now(),
        );
        await _db.accountDao.updateAccount(flaggedAcc);

        // Self-heal: recalculate and update database balance
        await recalculateAllBalances(accountId: acc.id);
        
        final selfHealMsg = '[$timestamp] SELF-HEALED: Successfully rebuilt and updated account "${acc.name}" balance to ₹${expectedBalance / 100.0}.\n';
        try {
          logFile.writeAsStringSync(selfHealMsg, mode: FileMode.append);
        } catch (_) {}
      }
    }

    // Verify equation Assets - Liabilities = Net Worth
    final updatedAccounts = await query.get();
    final summary = FinancialCalculationService.calculateAccountSummary(updatedAccounts);
    final calculatedNetWorth = summary.totalAssets - summary.totalLiabilities;
    
    if (summary.netAssets != calculatedNetWorth) {
      final equationDiscrepancyMsg = '[$timestamp] CRITICAL EQUATION FAILURE: Assets (${summary.totalAssets / 100.0}) - Liabilities (${summary.totalLiabilities / 100.0}) != Net Worth (${summary.netAssets / 100.0}). Difference: ₹${(calculatedNetWorth - summary.netAssets).abs() / 100.0}.\n';
      try {
        logFile.writeAsStringSync(equationDiscrepancyMsg, mode: FileMode.append);
      } catch (_) {}
    } else {
      final successMsg = '[$timestamp] VALIDATION SUCCESS: Assets (${summary.totalAssets / 100.0}) - Liabilities (${summary.totalLiabilities / 100.0}) = Net Worth (${summary.netAssets / 100.0}). All accounts verified.\n';
      try {
        logFile.writeAsStringSync(successMsg, mode: FileMode.append);
      } catch (_) {}
    }
  }
}

final balanceEngineProvider = Provider<BalanceEngine>((ref) {
  final db = ref.watch(databaseProvider);
  return BalanceEngine(db);
});
