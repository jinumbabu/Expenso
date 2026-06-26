import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'dart:developer' as dev;
import '../database/app_database.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class LedgerAgent {
  final AppDatabase _db;

  LedgerAgent(this._db);

  /// Reconciles a new transaction: checks for duplicates, merges if found,
  /// otherwise inserts and updates the associated account ledger balances.
  Future<void> reconcileTransaction(Transaction newTx, {double confidence = 1.0}) async {
    dev.log('LedgerAgent: Reconciling transaction: ${newTx.merchant}, amount: ${newTx.amount}');
    
    // 1. Duplicate & Merge Check

    // Fetch transactions from the same day
    final startOfDay = DateTime(newTx.date.year, newTx.date.month, newTx.date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final existingTxs = await (_db.select(_db.transactions)
      ..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.date.isSmallerOrEqualValue(endOfDay))
    ).get();

    Transaction? duplicateTx;
    for (var ext in existingTxs) {
      // Check if amount is identical (or very close)
      final amountMatches = (ext.amount - newTx.amount).abs() < 100; // within 1 rupee/dollar (100 cents)
      if (amountMatches) {
        // Check if merchants are similar
        final extMerchant = (ext.merchant ?? '').toLowerCase();
        final newMerchant = (newTx.merchant ?? '').toLowerCase();
        
        final merchantMatches = extMerchant.contains(newMerchant) || 
                                newMerchant.contains(extMerchant) ||
                                (ext.description ?? '').toLowerCase().contains(newMerchant);
                                
        if (merchantMatches) {
          duplicateTx = ext;
          break;
        }
      }
    }

    if (duplicateTx != null) {
      // 2. Auto Merge logic
      dev.log('LedgerAgent: Duplicate detected. Merging with existing transaction: ${duplicateTx.id}');
      
      final mergedDesc = _mergeStrings(duplicateTx.description, newTx.description);
      final mergedMerchant = _mergeStrings(duplicateTx.merchant, newTx.merchant) ?? 'Merged Merchant';

      final mergedTx = duplicateTx.copyWith(
        description: Value(mergedDesc),
        merchant: Value(mergedMerchant),
        // If the new one contains category or payment details, merge them in
        categoryId: Value(duplicateTx.categoryId ?? newTx.categoryId),
        paymentMethodId: Value(duplicateTx.paymentMethodId ?? newTx.paymentMethodId),
        syncStatus: 'pending', // Re-mark for upload sync
        updatedAt: DateTime.now(),
      );

      await _db.transactionDao.updateTransaction(mergedTx);

      // Log the merge decision in AgentLogs
      await _db.agentLogDao.insertLog(
        AgentLog(
          id: const Uuid().v4(),
          agentName: 'Ledger Intelligence Agent',
          actionType: 'TRANSACTION_MERGED',
          decisionDescription: 'Auto-merged transaction ${newTx.id} into existing ${duplicateTx.id}. Amount: ₹${newTx.amount / 100.0}, Merchant: $mergedMerchant',
          confidenceScore: confidence,
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    // 3. No Duplicate: Insert new Transaction
    dev.log('LedgerAgent: No duplicate found. Inserting new transaction: ${newTx.id}');
    await _db.transactionDao.insertTransaction(newTx);

    // 4. Reconcile Account Balance
    await _reconcileAccountBalance(newTx, confidence);
  }

  Future<void> _reconcileAccountBalance(Transaction tx, double confidence) async {
    try {
      final String accountName = tx.source == 'sms' ? 'Bank Account' : 'Cash Wallet';
      
      // Look for an existing account matching the name, or create one
      var account = await (_db.select(_db.accounts)
        ..where((t) => t.name.equals(accountName))
        ..limit(1)
      ).getSingleOrNull();

      if (account == null) {
        account = Account(
          id: const Uuid().v4(),
          userId: tx.userId,
          name: accountName,
          type: tx.source == 'sms' ? 'bank' : 'cash',
          balance: 1000000, // Default seed balance: ₹10,000 (cents)
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _db.into(_db.accounts).insert(account);
      }

      // Adjust balance based on transaction type
      int newBalance = account.balance;
      if (tx.type == 'expense') {
        newBalance -= tx.amount.toInt();
      } else if (tx.type == 'income') {
        newBalance += tx.amount.toInt();
      }

      final updatedAccount = account.copyWith(
        balance: newBalance,
        updatedAt: DateTime.now(),
      );

      await _db.update(_db.accounts).replace(updatedAccount);

      // Log the balance adjustment
      await _db.agentLogDao.insertLog(
        AgentLog(
          id: const Uuid().v4(),
          agentName: 'Ledger Intelligence Agent',
          actionType: 'ACCOUNT_RECONCILED',
          decisionDescription: 'Adjusted account ($accountName) balance from ₹${account.balance / 100.0} to ₹${newBalance / 100.0} due to transaction ${tx.id}',
          confidenceScore: confidence,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      dev.log('LedgerAgent: Failed to reconcile account balance: $e');
    }
  }

  String? _mergeStrings(String? a, String? b) {
    if (a == null || a.isEmpty) return b;
    if (b == null || b.isEmpty) return a;
    if (a.toLowerCase() == b.toLowerCase()) return a;
    if (a.toLowerCase().contains(b.toLowerCase())) return a;
    if (b.toLowerCase().contains(a.toLowerCase())) return b;
    return '$a / $b';
  }
}

final Provider<LedgerAgent> ledgerAgentProvider = Provider<LedgerAgent>((ref) {
  final db = ref.watch(databaseProvider);
  return LedgerAgent(db);
});
