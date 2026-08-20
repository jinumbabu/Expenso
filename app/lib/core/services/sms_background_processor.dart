import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../security/secure_storage_service.dart';
import 'sms_agent.dart';
import 'ledger_agent.dart';
import 'notification_service.dart';
import 'sms_account_matcher.dart';
import 'balance_engine.dart';
import 'parser_agent.dart';

class SmsBackgroundProcessor {
  static Future<void> processIncomingSms({
    required String? sender,
    required String body,
    required DateTime date,
    required String userId,
    required AppDatabase db,
    required SmsAgent smsAgent,
    required LedgerAgent ledgerAgent,
    required NotificationService notificationService,
    required SecureStorageService secureStorage,
    Function()? onUiInvalidate,
  }) async {
    final cleanBody = body.replaceAll('\n', ' ').trim();
    debugPrint("SmsBackgroundProcessor: Processing incoming SMS: $cleanBody");

    // Persist stats increment for scanned SMS
    try {
      final totalScannedStr = await secureStorage.read('sms_stats_total_scanned') ?? '0';
      final totalScanned = int.parse(totalScannedStr) + 1;
      await secureStorage.write('sms_stats_total_scanned', totalScanned.toString());
      await secureStorage.write('sms_stats_last_scan_time', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint("SmsBackgroundProcessor: Failed to increment total scanned stats: $e");
    }

    try {
      final result = await smsAgent.processSms(body, date, userId: userId, sender: sender);
      if (result != null) {
        // Increment financial detected stats
        try {
          final findStr = await secureStorage.read('sms_stats_financial_detected') ?? '0';
          final findCount = int.parse(findStr) + 1;
          await secureStorage.write('sms_stats_financial_detected', findCount.toString());
          await secureStorage.write('sms_stats_last_processed_time', DateTime.now().toIso8601String());
        } catch (_) {}

        bool matched = false;

        if (result.transactionType == 'transfer' || result.category == 'Internal Transfer') {
          final lastFewDays = DateTime.now().subtract(const Duration(days: 3));
          final existingTransactions = await (db.select(db.transactions)
            ..where((t) => t.userId.equals(userId) & t.date.isBiggerOrEqualValue(lastFewDays) & t.deletedAt.isNull())
          ).get();

          final lowerBody = body.toLowerCase();
          bool currentIsDebit = true;
          if (lowerBody.contains('credited') || lowerBody.contains('received') || lowerBody.contains('deposited')) {
            currentIsDebit = false;
          }

          Transaction? matchingTx;
          for (var tx in existingTransactions) {
            final isTxDebit = tx.type == 'expense' || tx.type == 'transfer_debit';
            if (currentIsDebit != isTxDebit) {
              final hasSameRef = result.referenceId != null && 
                                 tx.referenceNumber != null && 
                                 result.referenceId == tx.referenceNumber;
              final sameAmount = (result.amount * 100).round() == tx.amount;
              final closeTime = result.date.difference(tx.date).inMinutes.abs() <= 35;

              if (hasSameRef && sameAmount && closeTime) {
                matchingTx = tx;
                break;
              }
            }
          }

          if (matchingTx != null) {
            matched = true;
            // Record duplicate stats
            try {
              final dupStr = await secureStorage.read('sms_stats_duplicate_count') ?? '0';
              await secureStorage.write('sms_stats_duplicate_count', (int.parse(dupStr) + 1).toString());
            } catch (_) {}

            final accounts = await (db.select(db.accounts)..where((a) => a.userId.equals(userId))).get();
            final currentAccMatch = SmsAccountMatcher.matchAccount(
              smsText: result.account,
              existingAccounts: accounts,
              cardOrAccount: result.accountNumber,
              sender: sender,
            );

            var currentAcc = currentAccMatch.matchedAccount;
            if (currentAcc == null) {
              final type = currentAccMatch.accountType;
              final name = currentAccMatch.displayTitle;
              final isCC = type == 'credit_card';
              final newId = const Uuid().v4();
              final now = DateTime.now();
              final newAcc = Account(
                id: newId,
                userId: userId,
                name: name,
                type: type,
                balance: 0,
                isDefault: false,
                isEstimated: false,
                createdAt: now,
                updatedAt: now,
                bankName: currentAccMatch.bankName,
                currency: 'INR',
                colorTheme: isCC ? '0xFFFF3B30' : '0xFF0066FF',
                icon: isCC ? 'credit_card' : 'account_balance',
                isActive: true,
                last4Digits: currentAccMatch.last4,
              );
              await db.into(db.accounts).insert(newAcc);
              currentAcc = newAcc;
            }

            final debitAccId = currentIsDebit ? currentAcc.id : matchingTx.accountId;
            final creditAccId = currentIsDebit ? matchingTx.accountId : currentAcc.id;

            if (debitAccId != null && creditAccId != null) {
              final sourceName = currentIsDebit ? currentAccMatch.displayTitle : matchingTx.merchant ?? 'Account';
              final destName = currentIsDebit ? matchingTx.merchant ?? 'Account' : currentAccMatch.displayTitle;

              final updatedTx = matchingTx.copyWith(
                type: 'transfer',
                accountId: Value(debitAccId),
                referenceNumber: Value(creditAccId),
                description: Value('SMS Transfer: $sourceName to $destName'),
                updatedAt: DateTime.now(),
              );
              await db.transactionDao.updateTransaction(updatedTx);
              await BalanceEngine(db).reconcileOnEdit(matchingTx, updatedTx);

              if (onUiInvalidate != null) onUiInvalidate();

              final isNotificationsEnabled = await secureStorage.getSmsNotificationsEnabled() ?? true;
              if (isNotificationsEnabled) {
                final formattedAmount = (result.amount).toStringAsFixed(2);
                await notificationService.sendProactiveAlert(
                  userId,
                  title: 'SMS Transfer Reconciled! ⇄',
                  body: '$sourceName → $destName\n₹$formattedAmount',
                  priority: 'high',
                );
              }
            }
          }

          if (!matched) {
            final existingDrafts = await db.transactionDraftDao.getDraftsForUser(userId);
            TransactionDraft? matchingDraft;
            for (var draft in existingDrafts) {
              final isDraftDebit = draft.type == 'expense' || draft.category == 'Internal Transfer' || (draft.smsBody != null && (draft.smsBody!.toLowerCase().contains('sent') || draft.smsBody!.toLowerCase().contains('debited')));
              if (currentIsDebit != isDraftDebit) {
                final hasSameRef = result.referenceId != null &&
                                   draft.smsBody != null &&
                                   draft.smsBody!.contains(result.referenceId!);
                final sameAmount = draft.amount == (result.amount * 100).round();
                final closeTime = result.date.difference(draft.date).inMinutes.abs() <= 35;

                if (hasSameRef && sameAmount && closeTime) {
                  matchingDraft = draft;
                  break;
                }
              }
            }

            if (matchingDraft != null) {
              matched = true;
              // Record duplicate stats
              try {
                final dupStr = await secureStorage.read('sms_stats_duplicate_count') ?? '0';
                await secureStorage.write('sms_stats_duplicate_count', (int.parse(dupStr) + 1).toString());
              } catch (_) {}

              final accounts = await (db.select(db.accounts)..where((a) => a.userId.equals(userId))).get();
              final currentAccMatch = SmsAccountMatcher.matchAccount(
                smsText: result.account,
                existingAccounts: accounts,
                cardOrAccount: result.accountNumber,
                sender: sender,
              );
              final currentAcc = currentAccMatch.matchedAccount;

              final draftAccMatch = SmsAccountMatcher.matchAccount(
                smsText: matchingDraft.smsBody ?? '',
                existingAccounts: accounts,
                cardOrAccount: matchingDraft.cardOrAccount,
                sender: matchingDraft.smsSender,
              );
              final draftAcc = draftAccMatch.matchedAccount;

              final debitAcc = currentIsDebit ? currentAcc : draftAcc;
              final creditAcc = currentIsDebit ? draftAcc : currentAcc;

              final sourceName = currentIsDebit ? currentAccMatch.displayTitle : draftAccMatch.displayTitle;
              final destName = currentIsDebit ? draftAccMatch.displayTitle : currentAccMatch.displayTitle;

              final metadata = {
                'fromAccountId': debitAcc?.id,
                'toAccountId': creditAcc?.id,
                'fromAccountName': sourceName,
                'toAccountName': destName,
                'refNumber': result.referenceId,
              };

              final updatedDraft = matchingDraft.copyWith(
                type: 'transfer',
                category: const Value('Transfer'),
                amount: (result.amount * 100).round(),
                merchant: Value(destName),
                description: Value('SMS Transfer: $sourceName to $destName'),
                cardOrAccount: Value(debitAcc?.last4Digits ?? matchingDraft.cardOrAccount),
                confidenceScore: const Value(0.85),
                supportingSms: Value(jsonEncode(metadata)),
              );

              await db.update(db.transactionDrafts).replace(updatedDraft);

              if (onUiInvalidate != null) onUiInvalidate();

              final isNotificationsEnabled = await secureStorage.getSmsNotificationsEnabled() ?? true;
              if (isNotificationsEnabled) {
                final formattedAmount = (result.amount).toStringAsFixed(2);
                await notificationService.sendProactiveAlert(
                  userId,
                  title: 'Pending SMS Transfer ⇄',
                  body: '$sourceName → $destName\n₹$formattedAmount',
                  priority: 'normal',
                );
              }
            }
          }
        }

        if (matched) {
          return;
        }

        // Resolve Category and Payment Method IDs
        final categoryId = result.categoryOverrideId ?? await _resolveCategoryId(db, result.merchant, result.transactionType, userId, classifiedCategory: result.category);
        final paymentMethodId = await _resolvePaymentMethodId(db, result.paymentMode ?? 'UPI', userId);

        if (result.confidence < 0.90) {
          // Increment pending transaction stats
          try {
            final pendStr = await secureStorage.read('sms_stats_pending_count') ?? '0';
            await secureStorage.write('sms_stats_pending_count', (int.parse(pendStr) + 1).toString());
            
            final txDetStr = await secureStorage.read('sms_stats_transactions_detected') ?? '0';
            await secureStorage.write('sms_stats_transactions_detected', (int.parse(txDetStr) + 1).toString());
          } catch (_) {}

          final draft = TransactionDraft(
            id: const Uuid().v4(),
            userId: userId,
            amount: (result.amount * 100).round(),
            type: result.transactionType,
            currency: 'INR',
            merchant: result.merchant,
            description: 'SMS Alert: ${result.account}',
            date: result.date,
            smsSender: sender,
            cardOrAccount: result.accountNumber,
            smsBody: body,
            originalSmsId: null,
            createdAt: DateTime.now(),
            categoryId: categoryId,
            category: result.category,
            confidenceScore: result.confidence,
          );
          await db.transactionDraftDao.insertDraft(draft);

          if (onUiInvalidate != null) onUiInvalidate();

          final isNotificationsEnabled = await secureStorage.getSmsNotificationsEnabled() ?? true;
          if (isNotificationsEnabled) {
            final isTransfer = result.transactionType == 'transfer';
            final formattedAmount = (result.amount).toStringAsFixed(2);
            await notificationService.sendProactiveAlert(
              userId,
              title: isTransfer ? 'Pending SMS Transfer ⇄' : 'New transaction to review! 📝',
              body: isTransfer 
                  ? '${result.account} → ${result.merchant ?? 'Unknown'}\n₹$formattedAmount' 
                  : 'Uncertain transaction: ₹$formattedAmount via ${result.account}. Please review and approve.',
              priority: 'normal',
            );
          }
          return;
        }

        final tx = Transaction(
          id: const Uuid().v4(),
          userId: userId,
          accountId: null, // Link to account resolved by LedgerAgent
          categoryId: categoryId,
          paymentMethodId: paymentMethodId,
          type: result.transactionType,
          amount: (result.amount * 100).round(),
          currency: 'INR',
          description: 'SMS Alert: ${result.account}',
          merchant: result.merchant,
          date: result.date,
          source: 'sms',
          confidenceScore: result.confidence,
          isRecurring: false,
          syncStatus: 'pending',
          transactionType: result.category,
          accountType: result.accountType,
          billStatus: result.billStatus,
          dueDate: result.dueDate,
          referenceNumber: result.referenceId,
          aiClassification: result.category,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final reconciliationResult = await ledgerAgent.reconcileTransaction(
          tx, 
          confidence: result.confidence,
          importedBalance: result.balance != null ? (result.balance! * 100).round() : null,
        );

        if (reconciliationResult.status == ReconciliationStatus.matchingManual) {
          // Increment pending transaction stats (matches manual)
          try {
            final pendStr = await secureStorage.read('sms_stats_pending_count') ?? '0';
            await secureStorage.write('sms_stats_pending_count', (int.parse(pendStr) + 1).toString());
            
            final txDetStr = await secureStorage.read('sms_stats_transactions_detected') ?? '0';
            await secureStorage.write('sms_stats_transactions_detected', (int.parse(txDetStr) + 1).toString());
          } catch (_) {}

          final draft = TransactionDraft(
            id: const Uuid().v4(),
            userId: userId,
            amount: (result.amount * 100).round(),
            type: result.transactionType,
            currency: 'INR',
            merchant: result.merchant,
            description: 'SMS Alert: ${result.account}',
            date: result.date,
            smsSender: sender,
            cardOrAccount: result.accountNumber,
            smsBody: body,
            originalSmsId: null,
            createdAt: DateTime.now(),
            categoryId: categoryId,
            category: result.category,
            confidenceScore: result.confidence,
            matchingTransactionId: reconciliationResult.matchingManualId,
          );
          await db.transactionDraftDao.insertDraft(draft);

          if (onUiInvalidate != null) onUiInvalidate();

          final isNotificationsEnabled = await secureStorage.getSmsNotificationsEnabled() ?? true;
          if (isNotificationsEnabled) {
            await notificationService.sendProactiveAlert(
              userId,
              title: 'Matching Manual Entry Found 🔗',
              body: 'An SMS matches your manual entry: ₹${result.amount} at ${result.merchant}. Please review and link them.',
              priority: 'normal',
            );
          }
          return;
        }

        if (onUiInvalidate != null) onUiInvalidate();

        if (reconciliationResult.status == ReconciliationStatus.inserted || reconciliationResult.status == ReconciliationStatus.updated) {
          // Increment auto saved transaction stats
          try {
            final autoSavedStr = await secureStorage.read('sms_stats_auto_saved_count') ?? '0';
            await secureStorage.write('sms_stats_auto_saved_count', (int.parse(autoSavedStr) + 1).toString());

            final txDetStr = await secureStorage.read('sms_stats_transactions_detected') ?? '0';
            await secureStorage.write('sms_stats_transactions_detected', (int.parse(txDetStr) + 1).toString());
          } catch (_) {}

          final formattedAmount = (result.amount).toStringAsFixed(2);
          final isTransfer = result.transactionType == 'transfer';
          final isNotificationsEnabled = await secureStorage.getSmsNotificationsEnabled() ?? true;
          if (isNotificationsEnabled) {
            await notificationService.sendProactiveAlert(
              userId,
              title: isTransfer ? 'Transfer Imported! ⇄' : 'Transaction Imported! 💸',
              body: isTransfer 
                  ? 'Transfer of ₹$formattedAmount imported.'
                  : '${result.transactionType == 'expense' ? 'Spent' : 'Received'} ₹$formattedAmount at ${result.merchant} via ${result.account}.',
              priority: 'high',
            );
          }
        } else if (reconciliationResult.status == ReconciliationStatus.skipped || reconciliationResult.status == ReconciliationStatus.merged) {
          // Increment duplicate stats if skipped/merged
          try {
            final dupStr = await secureStorage.read('sms_stats_duplicate_count') ?? '0';
            await secureStorage.write('sms_stats_duplicate_count', (int.parse(dupStr) + 1).toString());
          } catch (_) {}
        }
      } else {
        // Increment ignored stats
        try {
          final ignStr = await secureStorage.read('sms_stats_ignored_count') ?? '0';
          await secureStorage.write('sms_stats_ignored_count', (int.parse(ignStr) + 1).toString());
        } catch (_) {}

        if (_isTransactionKeywordsMatch(body)) {
          final unrecognized = UnrecognizedMessage(
            id: const Uuid().v4(),
            userId: userId,
            sender: sender,
            body: body,
            date: date,
            failureReason: 'Failed to extract banking/amount details',
            createdAt: DateTime.now(),
          );
          await db.unrecognizedMessageDao.insertUnrecognizedMessage(unrecognized);
          if (onUiInvalidate != null) onUiInvalidate();
        }
      }
    } catch (e) {
      debugPrint("SmsBackgroundProcessor: Error handling incoming SMS: $e");
      try {
        await secureStorage.write('sms_stats_last_error', e.toString());
      } catch (_) {}
    }
  }

  static bool _isTransactionKeywordsMatch(String body) {
    final lower = body.toLowerCase();
    return lower.contains('debited') ||
        lower.contains('credited') ||
        lower.contains('spent') ||
        lower.contains('withdrawn') ||
        lower.contains('deposited');
  }

  static Future<String?> _resolveCategoryId(AppDatabase db, String merchant, String type, String userId, {String? classifiedCategory}) async {
    String catName = classifiedCategory ?? (type == 'income' ? 'Salary' : 'Shopping');
    
    if (catName == 'General Income') {
      catName = 'General Income';
    } else if (catName == 'Personal Transfer') {
      catName = 'Personal Transfer';
    }
    
    if (classifiedCategory == null) {
      final lowerMerchant = merchant.toLowerCase();
      for (final entry in ParserAgent.keywordToCategory.entries) {
        if (lowerMerchant.contains(entry.key)) {
          catName = entry.value;
          break;
        }
      }
    }

    var cat = await (db.select(db.categories)
          ..where((t) => t.name.equals(catName) & (t.userId.equals(userId) | t.isSystemDefault.equals(true)))
          ..limit(1))
        .getSingleOrNull();

    if (cat == null) {
      final id = const Uuid().v4();
      final now = DateTime.now();
      await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          id: id,
          userId: userId,
          name: catName,
          type: type,
          isSystemDefault: const Value(false),
          createdAt: now,
          icon: Value(type == 'income' ? 'payments' : 'shopping_bag'),
          color: Value(type == 'income' ? '0xFF00FF88' : '0xFF8A2BE2'),
        ),
      );
      cat = await (db.select(db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
    }

    return cat?.id;
  }

  static Future<String?> _resolvePaymentMethodId(AppDatabase db, String mode, String userId) async {
    String queryMode = mode;
    if (mode == 'IMPS' || mode == 'NEFT' || mode == 'RTGS') {
      queryMode = 'Net Banking';
    }
    final pm = await (db.select(db.paymentMethods)
          ..where((t) => t.name.equals(queryMode) & (t.userId.equals(userId) | t.userId.equals('system')))
          ..limit(1))
        .getSingleOrNull();
    return pm?.id;
  }
}
