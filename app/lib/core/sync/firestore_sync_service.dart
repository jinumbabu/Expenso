import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class FirestoreSyncService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<StreamSubscription> _subscriptions = [];

  FirestoreSyncService(this._ref);

  void startRealTimeSync(String userId) {
    stopRealTimeSync();
    debugPrint('FirestoreSyncService: Starting real-time sync for user $userId');

    final db = _ref.read(databaseProvider);

    // 1. Sync accounts
    _subscriptions.add(
      _firestore.collection('users').doc(userId).collection('accounts').snapshots().listen((snapshot) async {
        for (var change in snapshot.docChanges) {
          final doc = change.doc;
          final data = doc.data();
          if (change.type == DocumentChangeType.removed || data == null) {
            await db.accountDao.deleteAccount(doc.id);
            continue;
          }

          try {
            final local = await db.accountDao.getAccountById(doc.id);
            final remoteUpdatedAt = DateTime.parse(data['updatedAt'] as String);

            if (local == null) {
              final account = Account(
                id: doc.id,
                userId: data['userId'] as String,
                name: data['name'] as String,
                type: data['type'] as String,
                balance: data['balance'] as int,
                isDefault: data['isDefault'] as bool,
                createdAt: DateTime.parse(data['createdAt'] as String),
                updatedAt: remoteUpdatedAt,
              );
              await db.accountDao.insertAccount(account);
            } else if (remoteUpdatedAt.isAfter(local.updatedAt)) {
              final updated = local.copyWith(
                name: data['name'] as String,
                type: data['type'] as String,
                balance: data['balance'] as int,
                isDefault: data['isDefault'] as bool,
                updatedAt: remoteUpdatedAt,
              );
              await db.accountDao.updateAccount(updated);
            } else if (local.updatedAt.isAfter(remoteUpdatedAt)) {
              await uploadAccount(local);
            }
          } catch (e) {
            debugPrint('Error syncing account: $e');
          }
        }
      })
    );

    // 2. Sync transactions
    _subscriptions.add(
      _firestore.collection('users').doc(userId).collection('transactions').snapshots().listen((snapshot) async {
        for (var change in snapshot.docChanges) {
          final doc = change.doc;
          final data = doc.data();
          if (change.type == DocumentChangeType.removed || data == null) {
            await db.transactionDao.hardDeleteTransaction(doc.id);
            continue;
          }

          try {
            final local = await db.transactionDao.getTransactionById(doc.id);
            final remoteUpdatedAt = DateTime.parse(data['updatedAt'] as String);
            final deletedAtStr = data['deletedAt'] as String?;
            final remoteDeletedAt = deletedAtStr != null ? DateTime.parse(deletedAtStr) : null;

            if (local == null) {
              if (remoteDeletedAt != null) continue;
              final tx = Transaction(
                id: doc.id,
                userId: data['userId'] as String,
                categoryId: data['categoryId'] as String?,
                paymentMethodId: data['paymentMethodId'] as String?,
                type: data['type'] as String,
                amount: data['amount'] as int,
                currency: data['currency'] as String,
                merchant: data['merchant'] as String?,
                description: data['description'] as String?,
                date: DateTime.parse(data['date'] as String),
                source: data['source'] as String,
                isRecurring: data['isRecurring'] as bool,
                confidenceScore: data['confidenceScore'] as double?,
                syncStatus: 'synced',
                createdAt: DateTime.parse(data['createdAt'] as String? ?? data['date'] as String),
                updatedAt: remoteUpdatedAt,
                deletedAt: remoteDeletedAt,
              );
              await db.transactionDao.insertTransaction(tx);
            } else if (remoteDeletedAt != null && local.deletedAt == null) {
              await db.transactionDao.hardDeleteTransaction(doc.id);
            } else if (remoteUpdatedAt.isAfter(local.updatedAt)) {
              // Remote is newer, check if local has pending changes (Conflict!)
              if (local.syncStatus == 'pending') {
                // Check if content is actually different
                final contentDiffers = local.amount != data['amount'] ||
                    local.merchant != data['merchant'] ||
                    local.description != data['description'] ||
                    local.categoryId != data['categoryId'] ||
                    local.paymentMethodId != data['paymentMethodId'] ||
                    local.date != DateTime.parse(data['date'] as String) ||
                    local.type != data['type'];

                if (contentDiffers) {
                  // Mark local as conflict
                  await db.transactionDao.updateTransaction(local.copyWith(syncStatus: 'conflict'));
                  continue;
                }
              }
              final tx = local.copyWith(
                categoryId: Value(data['categoryId'] as String?),
                paymentMethodId: Value(data['paymentMethodId'] as String?),
                type: data['type'] as String,
                amount: data['amount'] as int,
                merchant: Value(data['merchant'] as String?),
                description: Value(data['description'] as String?),
                date: DateTime.parse(data['date'] as String),
                updatedAt: remoteUpdatedAt,
                deletedAt: Value(remoteDeletedAt),
                syncStatus: 'synced',
              );
              await db.transactionDao.updateTransaction(tx);
            } else if (local.updatedAt.isAfter(remoteUpdatedAt) && local.syncStatus == 'pending') {
              await uploadTransaction(local);
            }
          } catch (e) {
            debugPrint('Error syncing transaction: $e');
          }
        }
      })
    );

    // 3. Sync budgets
    _subscriptions.add(
      _firestore.collection('users').doc(userId).collection('budgets').snapshots().listen((snapshot) async {
        for (var change in snapshot.docChanges) {
          final doc = change.doc;
          final data = doc.data();
          if (change.type == DocumentChangeType.removed || data == null) {
            await db.budgetDao.deleteBudget(doc.id);
            continue;
          }

          try {
            final local = await db.budgetDao.getBudgetById(doc.id);
            final remoteUpdatedAt = DateTime.parse(data['updatedAt'] as String);

            if (local == null) {
              final budget = Budget(
                id: doc.id,
                userId: data['userId'] as String,
                categoryId: data['categoryId'] as String?,
                period: data['period'] as String,
                amount: data['amount'] as int,
                startDate: DateTime.parse(data['startDate'] as String),
                endDate: data['endDate'] != null ? DateTime.parse(data['endDate'] as String) : null,
                createdAt: DateTime.parse(data['createdAt'] as String? ?? data['startDate'] as String),
                updatedAt: remoteUpdatedAt,
              );
              await db.budgetDao.insertBudget(budget);
            } else if (remoteUpdatedAt.isAfter(local.updatedAt)) {
              final updated = local.copyWith(
                categoryId: Value(data['categoryId'] as String?),
                period: data['period'] as String,
                amount: data['amount'] as int,
                startDate: DateTime.parse(data['startDate'] as String),
                endDate: Value(data['endDate'] != null ? DateTime.parse(data['endDate'] as String) : null),
                updatedAt: remoteUpdatedAt,
              );
              await db.budgetDao.updateBudget(updated);
            } else if (local.updatedAt.isAfter(remoteUpdatedAt)) {
              await uploadBudget(local);
            }
          } catch (e) {
            debugPrint('Error syncing budget: $e');
          }
        }
      })
    );

    // 4. Sync goals
    _subscriptions.add(
      _firestore.collection('users').doc(userId).collection('goals').snapshots().listen((snapshot) async {
        for (var change in snapshot.docChanges) {
          final doc = change.doc;
          final data = doc.data();
          if (change.type == DocumentChangeType.removed || data == null) {
            await db.goalDao.deleteGoal(doc.id);
            continue;
          }

          try {
            final local = await db.goalDao.getGoalById(doc.id);
            final remoteUpdatedAt = DateTime.parse(data['updatedAt'] as String);

            if (local == null) {
              final goal = Goal(
                id: doc.id,
                userId: data['userId'] as String,
                title: data['title'] as String,
                targetAmount: data['targetAmount'] as int,
                currentAmount: data['currentAmount'] as int,
                targetDate: DateTime.parse(data['targetDate'] as String),
                createdAt: DateTime.parse(data['createdAt'] as String? ?? data['targetDate'] as String),
                updatedAt: remoteUpdatedAt,
              );
              await db.goalDao.insertGoal(goal);
            } else if (remoteUpdatedAt.isAfter(local.updatedAt)) {
              final updated = local.copyWith(
                title: data['title'] as String,
                targetAmount: data['targetAmount'] as int,
                currentAmount: data['currentAmount'] as int,
                targetDate: DateTime.parse(data['targetDate'] as String),
                updatedAt: remoteUpdatedAt,
              );
              await db.goalDao.updateGoal(updated);
            } else if (local.updatedAt.isAfter(remoteUpdatedAt)) {
              await uploadGoal(local);
            }
          } catch (e) {
            debugPrint('Error syncing goal: $e');
          }
        }
      })
    );

    // 5. Sync notifications
    _subscriptions.add(
      _firestore.collection('users').doc(userId).collection('notifications').snapshots().listen((snapshot) async {
        for (var change in snapshot.docChanges) {
          final doc = change.doc;
          final data = doc.data();
          if (change.type == DocumentChangeType.removed || data == null) {
            await db.notificationDao.deleteNotification(doc.id);
            continue;
          }

          try {
            final local = await db.notificationDao.getNotificationById(doc.id);

            if (local == null) {
              final notif = AppNotification(
                id: doc.id,
                userId: data['userId'] as String,
                title: data['title'] as String,
                body: data['body'] as String,
                priority: data['priority'] as String,
                isRead: data['isRead'] as bool,
                createdAt: DateTime.parse(data['createdAt'] as String),
              );
              await db.notificationDao.insertNotification(notif);
            } else if (data['isRead'] as bool != local.isRead) {
              if (data['isRead'] as bool) {
                await db.notificationDao.markAsRead(doc.id);
              }
            }
          } catch (e) {
            debugPrint('Error syncing notification: $e');
          }
        }
      })
    );

    // 6. Sync AI Memory
    _subscriptions.add(
      _firestore.collection('users').doc(userId).collection('ai_memories').snapshots().listen((snapshot) async {
        for (var change in snapshot.docChanges) {
          final doc = change.doc;
          final data = doc.data();
          if (change.type == DocumentChangeType.removed || data == null) {
            await db.aiMemoryDao.deleteMemory(doc.id);
            continue;
          }

          try {
            final local = await db.aiMemoryDao.getMemoryById(doc.id);

            if (local == null) {
              final memory = AiMemoryItem(
                id: doc.id,
                userId: data['userId'] as String,
                memoryType: data['memoryType'] as String,
                memoryKey: data['memoryKey'] as String,
                memoryValue: data['memoryValue'] as String,
                confidence: data['confidence'] as double?,
                expiresAt: data['expiresAt'] != null ? DateTime.parse(data['expiresAt'] as String) : null,
                createdAt: DateTime.parse(data['createdAt'] as String),
                lastAccessedAt: data['lastAccessedAt'] != null ? DateTime.parse(data['lastAccessedAt'] as String) : null,
              );
              await db.aiMemoryDao.insertMemory(memory);
            } else {
              final remoteLast = data['lastAccessedAt'] != null ? DateTime.parse(data['lastAccessedAt'] as String) : null;
              if (remoteLast != null && (local.lastAccessedAt == null || remoteLast.isAfter(local.lastAccessedAt!))) {
                final updated = local.copyWith(
                  memoryValue: data['memoryValue'] as String,
                  confidence: Value(data['confidence'] as double?),
                  lastAccessedAt: Value(remoteLast),
                );
                await db.aiMemoryDao.updateMemory(updated);
              }
            }
          } catch (e) {
            debugPrint('Error syncing AI memory: $e');
          }
        }
      })
    );
  }

  void stopRealTimeSync() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    debugPrint('FirestoreSyncService: Stopped real-time sync.');
  }

  // Real-time Upload Helpers
  Future<void> uploadAccount(Account account) async {
    try {
      await _firestore
          .collection('users')
          .doc(account.userId)
          .collection('accounts')
          .doc(account.id)
          .set({
        'userId': account.userId,
        'name': account.name,
        'type': account.type,
        'balance': account.balance,
        'isDefault': account.isDefault,
        'createdAt': account.createdAt.toIso8601String(),
        'updatedAt': account.updatedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error uploading account to Firestore: $e');
    }
  }

  Future<void> deleteAccount(String userId, String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Error deleting account from Firestore: $e');
    }
  }

  Future<void> uploadTransaction(Transaction tx) async {
    try {
      await _firestore
          .collection('users')
          .doc(tx.userId)
          .collection('transactions')
          .doc(tx.id)
          .set({
        'userId': tx.userId,
        'categoryId': tx.categoryId,
        'paymentMethodId': tx.paymentMethodId,
        'type': tx.type,
        'amount': tx.amount,
        'currency': tx.currency,
        'merchant': tx.merchant,
        'description': tx.description,
        'date': tx.date.toIso8601String(),
        'source': tx.source,
        'isRecurring': tx.isRecurring,
        'confidenceScore': tx.confidenceScore,
        'createdAt': tx.createdAt.toIso8601String(),
        'updatedAt': tx.updatedAt.toIso8601String(),
        'deletedAt': tx.deletedAt?.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error uploading transaction to Firestore: $e');
    }
  }

  Future<void> deleteTransaction(String userId, String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Error deleting transaction from Firestore: $e');
    }
  }

  Future<void> uploadBudget(Budget budget) async {
    try {
      await _firestore
          .collection('users')
          .doc(budget.userId)
          .collection('budgets')
          .doc(budget.id)
          .set({
        'userId': budget.userId,
        'categoryId': budget.categoryId,
        'amount': budget.amount,
        'period': budget.period,
        'startDate': budget.startDate.toIso8601String(),
        'endDate': budget.endDate?.toIso8601String(),
        'createdAt': budget.createdAt.toIso8601String(),
        'updatedAt': budget.updatedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error uploading budget to Firestore: $e');
    }
  }

  Future<void> deleteBudget(String userId, String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Error deleting budget from Firestore: $e');
    }
  }

  Future<void> uploadGoal(Goal goal) async {
    try {
      await _firestore
          .collection('users')
          .doc(goal.userId)
          .collection('goals')
          .doc(goal.id)
          .set({
        'userId': goal.userId,
        'title': goal.title,
        'targetAmount': goal.targetAmount,
        'currentAmount': goal.currentAmount,
        'targetDate': goal.targetDate.toIso8601String(),
        'createdAt': goal.createdAt.toIso8601String(),
        'updatedAt': goal.updatedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error uploading goal to Firestore: $e');
    }
  }

  Future<void> deleteGoal(String userId, String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Error deleting goal from Firestore: $e');
    }
  }

  Future<void> uploadNotification(AppNotification notif) async {
    try {
      await _firestore
          .collection('users')
          .doc(notif.userId)
          .collection('notifications')
          .doc(notif.id)
          .set({
        'userId': notif.userId,
        'title': notif.title,
        'body': notif.body,
        'priority': notif.priority,
        'isRead': notif.isRead,
        'createdAt': notif.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error uploading notification to Firestore: $e');
    }
  }

  Future<void> deleteNotification(String userId, String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification from Firestore: $e');
    }
  }

  Future<void> uploadAiMemory(AiMemoryItem memory) async {
    try {
      await _firestore
          .collection('users')
          .doc(memory.userId)
          .collection('ai_memories')
          .doc(memory.id)
          .set({
        'userId': memory.userId,
        'memoryType': memory.memoryType,
        'memoryKey': memory.memoryKey,
        'memoryValue': memory.memoryValue,
        'confidence': memory.confidence,
        'expiresAt': memory.expiresAt?.toIso8601String(),
        'createdAt': memory.createdAt.toIso8601String(),
        'lastAccessedAt': memory.lastAccessedAt?.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error uploading AI memory to Firestore: $e');
    }
  }

  Future<void> deleteAiMemory(String userId, String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_memories')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Error deleting AI memory from Firestore: $e');
    }
  }

  // Bidirectional Bulk Sync
  Future<void> syncLocalToCloud(String userId) async {
    try {
      final db = _ref.read(databaseProvider);
      final transactions = await db.transactionDao.getTransactionsForUser(userId);
      final budgets = await db.budgetDao.getBudgetsForUser(userId);
      final goals = await db.goalDao.getGoalsForUser(userId);
      final accounts = await db.accountDao.getAccountsForUser(userId);
      final notifications = await db.notificationDao.getNotificationsForUser(userId);
      final memories = await db.aiMemoryDao.getMemories(userId);

      for (var acc in accounts) {
        await uploadAccount(acc);
      }

      for (var tx in transactions) {
        if (tx.syncStatus == 'pending') {
          await uploadTransaction(tx);
          await db.transactionDao.updateTransaction(tx.copyWith(syncStatus: 'synced'));
        }
      }

      for (var budget in budgets) {
        await uploadBudget(budget);
      }

      for (var goal in goals) {
        await uploadGoal(goal);
      }

      for (var notif in notifications) {
        await uploadNotification(notif);
      }

      for (var mem in memories) {
        await uploadAiMemory(mem);
      }
    } catch (e) {
      debugPrint('Error in syncLocalToCloud: $e');
    }
  }

  Future<void> syncCloudToLocal(String userId) async {
    try {
      final db = _ref.read(databaseProvider);

      // Fetch accounts
      final accSnap = await _firestore.collection('users').doc(userId).collection('accounts').get();
      for (var doc in accSnap.docs) {
        final data = doc.data();
        final local = await db.accountDao.getAccountById(doc.id);
        final remoteUpdatedAt = DateTime.parse(data['updatedAt'] as String);

        if (local == null) {
          final account = Account(
            id: doc.id,
            userId: data['userId'] as String,
            name: data['name'] as String,
            type: data['type'] as String,
            balance: data['balance'] as int,
            isDefault: data['isDefault'] as bool,
            createdAt: DateTime.parse(data['createdAt'] as String),
            updatedAt: remoteUpdatedAt,
          );
          await db.accountDao.insertAccount(account);
        } else if (remoteUpdatedAt.isAfter(local.updatedAt)) {
          final updated = local.copyWith(
            name: data['name'] as String,
            type: data['type'] as String,
            balance: data['balance'] as int,
            isDefault: data['isDefault'] as bool,
            updatedAt: remoteUpdatedAt,
          );
          await db.accountDao.updateAccount(updated);
        }
      }

      // Fetch transactions
      final txSnap = await _firestore.collection('users').doc(userId).collection('transactions').get();
      for (var doc in txSnap.docs) {
        final data = doc.data();
        final local = await db.transactionDao.getTransactionById(doc.id);
        final remoteUpdatedAt = DateTime.parse(data['updatedAt'] as String);
        final deletedAtStr = data['deletedAt'] as String?;
        final remoteDeletedAt = deletedAtStr != null ? DateTime.parse(deletedAtStr) : null;

        if (local == null) {
          if (remoteDeletedAt != null) continue;
          final tx = Transaction(
            id: doc.id,
            userId: data['userId'] as String,
            categoryId: data['categoryId'] as String?,
            paymentMethodId: data['paymentMethodId'] as String?,
            type: data['type'] as String,
            amount: data['amount'] as int,
            currency: data['currency'] as String,
            merchant: data['merchant'] as String?,
            description: data['description'] as String?,
            date: DateTime.parse(data['date'] as String),
            source: data['source'] as String,
            isRecurring: data['isRecurring'] as bool,
            confidenceScore: data['confidenceScore'] as double?,
            syncStatus: 'synced',
            createdAt: DateTime.parse(data['createdAt'] as String? ?? data['date'] as String),
            updatedAt: remoteUpdatedAt,
            deletedAt: remoteDeletedAt,
          );
          await db.transactionDao.insertTransaction(tx);
        } else if (remoteDeletedAt != null && local.deletedAt == null) {
          await db.transactionDao.hardDeleteTransaction(doc.id);
        } else if (remoteUpdatedAt.isAfter(local.updatedAt)) {
          final tx = local.copyWith(
            categoryId: Value(data['categoryId'] as String?),
            paymentMethodId: Value(data['paymentMethodId'] as String?),
            type: data['type'] as String,
            amount: data['amount'] as int,
            merchant: Value(data['merchant'] as String?),
            description: Value(data['description'] as String?),
            date: DateTime.parse(data['date'] as String),
            updatedAt: remoteUpdatedAt,
            deletedAt: Value(remoteDeletedAt),
            syncStatus: 'synced',
          );
          await db.transactionDao.updateTransaction(tx);
        }
      }

      // Fetch budgets
      final budgetSnap = await _firestore.collection('users').doc(userId).collection('budgets').get();
      for (var doc in budgetSnap.docs) {
        final data = doc.data();
        final local = await db.budgetDao.getBudgetById(doc.id);
        final remoteUpdatedAt = DateTime.parse(data['updatedAt'] as String);

        if (local == null) {
          final budget = Budget(
            id: doc.id,
            userId: data['userId'] as String,
            categoryId: data['categoryId'] as String?,
            period: data['period'] as String,
            amount: data['amount'] as int,
            startDate: DateTime.parse(data['startDate'] as String),
            endDate: data['endDate'] != null ? DateTime.parse(data['endDate'] as String) : null,
            createdAt: DateTime.parse(data['createdAt'] as String? ?? data['startDate'] as String),
            updatedAt: remoteUpdatedAt,
          );
          await db.budgetDao.insertBudget(budget);
        } else if (remoteUpdatedAt.isAfter(local.updatedAt)) {
          final updated = local.copyWith(
            categoryId: Value(data['categoryId'] as String?),
            period: data['period'] as String,
            amount: data['amount'] as int,
            startDate: DateTime.parse(data['startDate'] as String),
            endDate: Value(data['endDate'] != null ? DateTime.parse(data['endDate'] as String) : null),
            updatedAt: remoteUpdatedAt,
          );
          await db.budgetDao.updateBudget(updated);
        }
      }

      // Fetch goals
      final goalSnap = await _firestore.collection('users').doc(userId).collection('goals').get();
      for (var doc in goalSnap.docs) {
        final data = doc.data();
        final local = await db.goalDao.getGoalById(doc.id);
        final remoteUpdatedAt = DateTime.parse(data['updatedAt'] as String);

        if (local == null) {
          final goal = Goal(
            id: doc.id,
            userId: data['userId'] as String,
            title: data['title'] as String,
            targetAmount: data['targetAmount'] as int,
            currentAmount: data['currentAmount'] as int,
            targetDate: DateTime.parse(data['targetDate'] as String),
            createdAt: DateTime.parse(data['createdAt'] as String? ?? data['targetDate'] as String),
            updatedAt: remoteUpdatedAt,
          );
          await db.goalDao.insertGoal(goal);
        } else if (remoteUpdatedAt.isAfter(local.updatedAt)) {
          final updated = local.copyWith(
            title: data['title'] as String,
            targetAmount: data['targetAmount'] as int,
            currentAmount: data['currentAmount'] as int,
            targetDate: DateTime.parse(data['targetDate'] as String),
            updatedAt: remoteUpdatedAt,
          );
          await db.goalDao.updateGoal(updated);
        }
      }

      // Fetch notifications
      final notifSnap = await _firestore.collection('users').doc(userId).collection('notifications').get();
      for (var doc in notifSnap.docs) {
        final data = doc.data();
        final local = await db.notificationDao.getNotificationById(doc.id);

        if (local == null) {
          final notif = AppNotification(
            id: doc.id,
            userId: data['userId'] as String,
            title: data['title'] as String,
            body: data['body'] as String,
            priority: data['priority'] as String,
            isRead: data['isRead'] as bool,
            createdAt: DateTime.parse(data['createdAt'] as String),
          );
          await db.notificationDao.insertNotification(notif);
        } else if (data['isRead'] as bool != local.isRead) {
          if (data['isRead'] as bool) {
            await db.notificationDao.markAsRead(doc.id);
          }
        }
      }

      // Fetch AI Memories
      final memSnap = await _firestore.collection('users').doc(userId).collection('ai_memories').get();
      for (var doc in memSnap.docs) {
        final data = doc.data();
        final local = await db.aiMemoryDao.getMemoryById(doc.id);

        if (local == null) {
          final memory = AiMemoryItem(
            id: doc.id,
            userId: data['userId'] as String,
            memoryType: data['memoryType'] as String,
            memoryKey: data['memoryKey'] as String,
            memoryValue: data['memoryValue'] as String,
            confidence: data['confidence'] as double?,
            expiresAt: data['expiresAt'] != null ? DateTime.parse(data['expiresAt'] as String) : null,
            createdAt: DateTime.parse(data['createdAt'] as String),
            lastAccessedAt: data['lastAccessedAt'] != null ? DateTime.parse(data['lastAccessedAt'] as String) : null,
          );
          await db.aiMemoryDao.insertMemory(memory);
        } else {
          final remoteLast = data['lastAccessedAt'] != null ? DateTime.parse(data['lastAccessedAt'] as String) : null;
          if (remoteLast != null && (local.lastAccessedAt == null || remoteLast.isAfter(local.lastAccessedAt!))) {
            final updated = local.copyWith(
              memoryValue: data['memoryValue'] as String,
              confidence: Value(data['confidence'] as double?),
              lastAccessedAt: Value(remoteLast),
            );
            await db.aiMemoryDao.updateMemory(updated);
          }
        }
      }
    } catch (e) {
      debugPrint('Error in syncCloudToLocal: $e');
    }
  }
}

final Provider<FirestoreSyncService> firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  return FirestoreSyncService(ref);
});
