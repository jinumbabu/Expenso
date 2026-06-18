import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/dao/transaction_draft_dao.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/services/sms_parser_service.dart';

// TransactionDraftDao Provider
final Provider<TransactionDraftDao> transactionDraftDaoProvider = Provider<TransactionDraftDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.transactionDraftDao;
});

// Watch Transaction Drafts Stream Provider
final StreamProvider<List<TransactionDraft>> transactionDraftsStreamProvider = StreamProvider<List<TransactionDraft>>((ref) {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return const Stream.empty();
  return ref.watch(transactionDraftDaoProvider).watchDraftsForUser(userId);
});

// SMS Scanner State
class SmsScannerState {
  final bool isScanning;
  final String? errorMessage;
  final int newDraftsCount;

  SmsScannerState({
    this.isScanning = false,
    this.errorMessage,
    this.newDraftsCount = 0,
  });

  SmsScannerState copyWith({
    bool? isScanning,
    String? errorMessage,
    int? newDraftsCount,
  }) {
    return SmsScannerState(
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
      newDraftsCount: newDraftsCount ?? this.newDraftsCount,
    );
  }
}

// SMS Scanner Notifier
class SmsScannerNotifier extends StateNotifier<SmsScannerState> {
  final TransactionDraftDao _draftDao;
  final String? _userId;
  final SmsQuery _smsQuery = SmsQuery();

  SmsScannerNotifier(this._draftDao, this._userId) : super(SmsScannerState());

  Future<void> scanInbox() async {
    if (_userId == null) {
      state = state.copyWith(errorMessage: 'User not authenticated.');
      return;
    }

    state = state.copyWith(isScanning: true, errorMessage: null);

    try {
      final permission = await Permission.sms.status;
      if (!permission.isGranted) {
        final request = await Permission.sms.request();
        if (!request.isGranted) {
          state = state.copyWith(
            isScanning: false,
            errorMessage: 'SMS permission denied. You can still test with mock SMS entries below.',
          );
          return;
        }
      }

      final messages = await _smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
      );

      int addedCount = 0;
      for (final msg in messages) {
        if (msg.body == null || msg.id == null) continue;

        // Extract a unique identifier for this message
        final originalSmsId = '${msg.id}_${msg.date?.millisecondsSinceEpoch ?? 0}';

        // Check if already processed
        final alreadyProcessed = await _draftDao.hasSmsBeenProcessed(originalSmsId);
        if (alreadyProcessed) continue;

        // Parse message
        final parsed = SmsParserService.parseSms(msg.body!, msg.date ?? DateTime.now());
        if (parsed != null) {
          // Insert draft
          final draft = TransactionDraft(
            id: const Uuid().v4(),
            userId: _userId,
            amount: (parsed.amount * 100).toInt(), // Stored as minor units (cents/paise)
            type: parsed.type,
            currency: 'INR',
            merchant: parsed.merchant,
            description: 'SMS from ${msg.sender ?? "Unknown"}',
            date: parsed.date,
            smsSender: msg.sender,
            smsBody: msg.body,
            originalSmsId: originalSmsId,
            cardOrAccount: parsed.cardOrAccount,
            createdAt: DateTime.now(),
          );
          await _draftDao.insertDraft(draft);
          addedCount++;
        }
      }

      state = state.copyWith(isScanning: false, newDraftsCount: addedCount);
    } catch (e) {
      log('SmsScannerNotifier: Error scanning SMS: $e');
      state = state.copyWith(isScanning: false, errorMessage: 'Error scanning inbox: $e');
    }
  }

  /// Helper for Web/Desktop and manual testing: parses text manually entered by the user
  Future<bool> importMockSms(String sender, String body) async {
    if (_userId == null) return false;
    final parsed = SmsParserService.parseSms(body, DateTime.now());
    if (parsed == null) return false;

    final originalSmsId = 'mock_${body.hashCode}_${DateTime.now().millisecondsSinceEpoch}';

    final draft = TransactionDraft(
      id: const Uuid().v4(),
      userId: _userId,
      amount: (parsed.amount * 100).toInt(),
      type: parsed.type,
      currency: 'INR',
      merchant: parsed.merchant,
      description: 'Mock SMS from $sender',
      date: parsed.date,
      smsSender: sender,
      smsBody: body,
      originalSmsId: originalSmsId,
      cardOrAccount: parsed.cardOrAccount,
      createdAt: DateTime.now(),
    );

    await _draftDao.insertDraft(draft);
    return true;
  }

  Future<void> dismissDraft(String draftId) async {
    await _draftDao.deleteDraft(draftId);
  }
}

// SMS Scanner Provider
final StateNotifierProvider<SmsScannerNotifier, SmsScannerState> smsScannerProvider =
    StateNotifierProvider<SmsScannerNotifier, SmsScannerState>((ref) {
  final dao = ref.watch(transactionDraftDaoProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  return SmsScannerNotifier(dao, userId);
});
