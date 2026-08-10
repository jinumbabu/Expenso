import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as dev;
import '../database/app_database.dart';
import 'ledger_agent.dart';
import 'balance_engine.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class DuplicateScanner {
  final AppDatabase _db;

  DuplicateScanner(this._db);

  /// Scans all transactions for the given user, finds duplicates within 10-minute
  /// windows of each other, merges them, and deletes duplicates safely.
  Future<int> scanAndCleanupDuplicates(String userId) async {
    dev.log('DuplicateScanner: Starting duplicate scan for user: $userId');

    // 1. Fetch all transactions for the user (non-deleted, sorted by date)
    final txs = await (_db.select(_db.transactions)
      ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc)])
    ).get();

    if (txs.isEmpty) {
      dev.log('DuplicateScanner: No transactions to scan.');
      return 0;
    }

    // 2. Group transactions by account and amount
    final Map<String, List<Transaction>> groups = {};
    for (final tx in txs) {
      if (tx.accountId == null) continue;
      final key = "${tx.accountId}_${tx.amount}";
      groups.putIfAbsent(key, () => []).add(tx);
    }

    int duplicatesFound = 0;
    final ledgerAgent = LedgerAgent(_db);

    // 3. Scan each group for transactions within 10-minute window
    for (final group in groups.values) {
      if (group.length < 2) continue;

      final List<bool> mergedFlags = List.filled(group.length, false);

      for (int i = 0; i < group.length; i++) {
        if (mergedFlags[i]) continue;

        var baseTx = group[i];

        for (int j = i + 1; j < group.length; j++) {
          if (mergedFlags[j]) continue;

          final targetTx = group[j];

          // Check 10-minute window
          final diff = targetTx.date.difference(baseTx.date).abs();
          if (diff.inMinutes <= 10) {
            // Check merchant (fuzzy match)
            final m1 = (baseTx.merchant ?? '').toLowerCase().trim();
            final m2 = (targetTx.merchant ?? '').toLowerCase().trim();
            final merchantMatches = m1 == m2 || m1.contains(m2) || m2.contains(m1) || (m1.isEmpty && m2.isEmpty);
            if (!merchantMatches) continue;

            // Check reference number (if both exist, they must match)
            final ref1 = (baseTx.referenceNumber ?? '').trim().toLowerCase();
            final ref2 = (targetTx.referenceNumber ?? '').trim().toLowerCase();
            final refMatches = ref1 == ref2 || ref1.isEmpty || ref2.isEmpty;
            if (!refMatches) continue;

            dev.log('DuplicateScanner: Merging duplicate transaction ${targetTx.id} into ${baseTx.id}');

            // Merge descriptions and merchants
            final mergedDesc = _mergeStrings(baseTx.description, targetTx.description);
            final mergedMerchant = _mergeStrings(baseTx.merchant, targetTx.merchant) ?? 'Merged Merchant';

            // Merge supporting SMS lists
            List<String> smsList = [];
            if (baseTx.supportingSms != null && baseTx.supportingSms!.isNotEmpty) {
              try {
                smsList = List<String>.from(jsonDecode(baseTx.supportingSms!));
              } catch (_) {}
            }
            if (baseTx.description != null && !smsList.contains(baseTx.description)) {
              smsList.add(baseTx.description!);
            }
            
            if (targetTx.supportingSms != null && targetTx.supportingSms!.isNotEmpty) {
              try {
                final targetSms = List<String>.from(jsonDecode(targetTx.supportingSms!));
                for (final s in targetSms) {
                  if (!smsList.contains(s)) smsList.add(s);
                }
              } catch (_) {}
            }
            if (targetTx.description != null && !smsList.contains(targetTx.description)) {
              smsList.add(targetTx.description!);
            }

            final mergedRef = ref1.isNotEmpty ? baseTx.referenceNumber : targetTx.referenceNumber;

            // Update base transaction fingerprint
            final fingerprint = ledgerAgent.generateFingerprint(
              accountId: baseTx.accountId,
              amount: baseTx.amount.toInt(),
              merchant: mergedMerchant,
              date: baseTx.date,
              referenceNumber: mergedRef,
            );

            baseTx = baseTx.copyWith(
              description: Value(mergedDesc),
              merchant: Value(mergedMerchant),
              referenceNumber: Value(mergedRef),
              fingerprint: Value(fingerprint),
              supportingSms: Value(jsonEncode(smsList)),
              categoryId: Value(baseTx.categoryId ?? targetTx.categoryId),
              subcategoryId: Value(baseTx.subcategoryId ?? targetTx.subcategoryId),
              paymentMethodId: Value(baseTx.paymentMethodId ?? targetTx.paymentMethodId),
              updatedAt: DateTime.now(),
            );

            // Update in DB
            await _db.transactionDao.updateTransaction(baseTx);

            // Delete duplicate target transaction
            await _db.transactionDao.hardDeleteTransaction(targetTx.id);

            mergedFlags[j] = true;
            duplicatesFound++;
          }
        }
      }
    }

    if (duplicatesFound > 0) {
      dev.log('DuplicateScanner: Recalculating account balances after merging $duplicatesFound duplicates.');
      await BalanceEngine(_db).recalculateAllBalances();
    }

    dev.log('DuplicateScanner: Completed duplicate scan. Merged $duplicatesFound transaction(s).');
    return duplicatesFound;
  }

  String _mergeStrings(String? a, String? b) {
    if (a == null || a.isEmpty) return b ?? '';
    if (b == null || b.isEmpty) return a;
    if (a.toLowerCase().contains(b.toLowerCase())) return a;
    if (b.toLowerCase().contains(a.toLowerCase())) return b;
    if (a.startsWith('SMS Alert:') && b.startsWith('SMS Alert:')) return a;
    return '$a / $b';
  }
}

final Provider<DuplicateScanner> duplicateScannerProvider = Provider<DuplicateScanner>((ref) {
  final db = ref.watch(databaseProvider);
  return DuplicateScanner(db);
});
