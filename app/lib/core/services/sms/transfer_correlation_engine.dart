import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../database/app_database.dart';
import '../sms_agent.dart';
import '../sms_account_matcher.dart';

class CorrelationResult {
  final Transaction? matchedTx;
  final TransactionDraft? matchedDraft;
  final int score;

  CorrelationResult({this.matchedTx, this.matchedDraft, required this.score});
}

class TransferCorrelationEngine {
  final AppDatabase _db;

  TransferCorrelationEngine(this._db);

  /// Analyzes an incoming SMS candidate and searches for a counterpart in recently saved transactions or drafts.
  /// Returns a CorrelationResult if a counterpart is matched.
  Future<CorrelationResult?> correlate(
    SmsAgentResult candidate,
    String userId,
    String? sender,
  ) async {
    final searchWindowStart = candidate.date.subtract(const Duration(hours: 3));
    final searchWindowEnd = candidate.date.add(const Duration(hours: 3));

    final isCandidateDebit = candidate.transactionType == 'expense';

    // 1. Scan recent transactions in the database (last 3 days)
    final recentTransactions = await (_db.select(_db.transactions)
      ..where((t) => t.userId.equals(userId) & 
                     t.date.isBetweenValues(candidate.date.subtract(const Duration(days: 3)), candidate.date.add(const Duration(days: 3))) &
                     t.deletedAt.isNull())
    ).get();

    Transaction? bestTxMatch;
    int bestTxScore = 0;

    for (var tx in recentTransactions) {
      final isTxDebit = tx.type == 'expense' || tx.type == 'transfer_debit' || tx.type == 'cash_withdrawal';
      
      // Top Priority: Exact Reference ID match
      if (candidate.referenceId != null && 
          candidate.referenceId!.isNotEmpty && 
          tx.referenceNumber != null && 
          tx.referenceNumber == candidate.referenceId) {
        return CorrelationResult(matchedTx: tx, score: 100);
      }

      if (isCandidateDebit == isTxDebit) continue; // Must be opposite directions if no ref match

      int score = 0;

      // Rule 2: Amount Match (+20)
      final candidateCents = (candidate.amount * 100).round();
      if ((candidateCents - tx.amount).abs() <= 1) { // 1 cent tolerance
        score += 20;
      }

      // Rule 3: Opposite Directions (+15)
      score += 15;

      // Rule 4: Same Date (+5)
      final isSameDay = candidate.date.year == tx.date.year &&
                        candidate.date.month == tx.date.month &&
                        candidate.date.day == tx.date.day;
      if (isSameDay) {
        score += 5;
      }

      // Rule 5: Close Time Window (+5)
      final timeDiffMin = candidate.date.difference(tx.date).inMinutes.abs();
      if (timeDiffMin <= 35) {
        score += 5;
      }

      // Rule 6: Narrative / Identity Signals (+10)
      final bodyLower = (candidate.merchant + " " + candidate.account).toLowerCase();
      final txDescLower = (tx.description ?? "").toLowerCase();
      final txMerchantLower = (tx.merchant ?? "").toLowerCase();
      if ((txMerchantLower.isNotEmpty && bodyLower.contains(txMerchantLower)) || 
          (candidate.merchant.isNotEmpty && txDescLower.contains(candidate.merchant.toLowerCase())) ||
          (txMerchantLower.isNotEmpty && txMerchantLower.contains('transfer')) ||
          bodyLower.contains('transfer')) {
        score += 10;
      }

      if (score >= 50 && score > bestTxScore) {
        bestTxScore = score;
        bestTxMatch = tx;
      }
    }

    if (bestTxMatch != null) {
      return CorrelationResult(matchedTx: bestTxMatch, score: bestTxScore);
    }

    // 2. Scan pending drafts in transaction_drafts table
    final pendingDrafts = await (_db.select(_db.transactionDrafts)
      ..where((t) => t.userId.equals(userId))
    ).get();

    TransactionDraft? bestDraftMatch;
    int bestDraftScore = 0;

    for (var draft in pendingDrafts) {
      // Top Priority: Exact Reference ID match
      if (candidate.referenceId != null && candidate.referenceId!.isNotEmpty) {
        String? draftRef;
        if (draft.supportingSms != null && draft.supportingSms!.startsWith('{')) {
          try {
            final meta = jsonDecode(draft.supportingSms!);
            draftRef = meta['refNumber'] as String?;
          } catch (_) {}
        }
        if (draftRef == candidate.referenceId || (draft.smsBody != null && draft.smsBody!.contains(candidate.referenceId!))) {
          return CorrelationResult(matchedDraft: draft, score: 100);
        }
      }

      final isDraftDebit = draft.type == 'expense' || 
                           draft.category == 'Internal Transfer' || 
                           (draft.smsBody != null && 
                            (draft.smsBody!.toLowerCase().contains('sent') || 
                             draft.smsBody!.toLowerCase().contains('debited')));

      if (isCandidateDebit == isDraftDebit) continue; // Must be opposite directions if no ref match

      int score = 0;

      // Rule 2: Amount Match (+20)
      final candidateCents = (candidate.amount * 100).round();
      if ((candidateCents - draft.amount).abs() <= 1) {
        score += 20;
      }

      // Rule 3: Opposite Directions (+15)
      score += 15;

      // Rule 4: Same Date (+5)
      final isSameDay = candidate.date.year == draft.date.year &&
                        candidate.date.month == draft.date.month &&
                        candidate.date.day == draft.date.day;
      if (isSameDay) {
        score += 5;
      }

      // Rule 5: Close Time Window (+5)
      final timeDiffMin = candidate.date.difference(draft.date).inMinutes.abs();
      if (timeDiffMin <= 35) {
        score += 5;
      }

      // Rule 6: Narrative / Identity Signals (+10)
      final bodyLower = (candidate.merchant + " " + candidate.account).toLowerCase();
      final draftDescLower = (draft.description ?? "").toLowerCase();
      final draftMerchantLower = (draft.merchant ?? "").toLowerCase();
      if ((draftMerchantLower.isNotEmpty && bodyLower.contains(draftMerchantLower)) || 
          (candidate.merchant.isNotEmpty && draftDescLower.contains(candidate.merchant.toLowerCase())) ||
          (draftMerchantLower.isNotEmpty && draftMerchantLower.contains('transfer')) ||
          bodyLower.contains('transfer')) {
        score += 10;
      }

      if (score >= 50 && score > bestDraftScore) {
        bestDraftScore = score;
        bestDraftMatch = draft;
      }
    }

    if (bestDraftMatch != null) {
      return CorrelationResult(matchedDraft: bestDraftMatch, score: bestDraftScore);
    }

    return null;
  }

  /// Automatically resolves drafts that have been waiting for their counterpart for over 24 hours.
  /// Such drafts are resolved as standard expenses or income.
  Future<void> resolveOrphanedTransferDrafts(String userId) async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));

    final orphanedDrafts = await (_db.select(_db.transactionDrafts)
      ..where((t) => t.userId.equals(userId) & t.category.equals('Transfer') & t.date.isSmallerThanValue(cutoff))
    ).get();

    for (var draft in orphanedDrafts) {
      if (draft.supportingSms != null && draft.supportingSms!.startsWith('{')) {
        try {
          final metadata = jsonDecode(draft.supportingSms!);
          if (metadata['status'] == 'WAITING_FOR_COUNTERPART') {
            final isDebit = draft.smsBody != null && 
                            (draft.smsBody!.toLowerCase().contains('sent') || 
                             draft.smsBody!.toLowerCase().contains('debited') ||
                             draft.smsBody!.toLowerCase().contains('paid'));

            final resolvedType = isDebit ? 'expense' : 'income';
            final resolvedCategoryName = isDebit ? 'Shopping' : 'Salary';

            // Fetch default category
            final cat = await (_db.select(_db.categories)
              ..where((c) => c.name.equals(resolvedCategoryName) & (c.userId.equals(userId) | c.isSystemDefault.equals(true)))
              ..limit(1)
            ).getSingleOrNull();

            final updatedDraft = draft.copyWith(
              type: resolvedType,
              category: Value(resolvedCategoryName),
              categoryId: Value(cat?.id),
              supportingSms: const Value(null),
            );

            await _db.update(_db.transactionDrafts).replace(updatedDraft);
            debugPrint("TransferCorrelationEngine: Resolved orphaned transfer draft ${draft.id} as $resolvedType");
          }
        } catch (e) {
          debugPrint("TransferCorrelationEngine: Error resolving orphaned draft: $e");
        }
      }
    }
  }
}
