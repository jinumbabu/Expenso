import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

class AuditLogger {
  final AppDatabase _db;

  AuditLogger(this._db);

  Future<void> logEvent({
    required String? userId,
    required String eventType,
    required String eventCategory,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final log = AuditLog(
        id: const Uuid().v4(),
        userId: userId,
        eventType: eventType,
        eventCategory: eventCategory,
        description: description,
        metadata: metadata != null ? jsonEncode(metadata) : null,
        createdAt: DateTime.now(),
      );
      await _db.auditLogDao.insertLog(log);
    } catch (e) {
      // Prevent logging failures from breaking primary application flows
      debugPrint('AuditLogger failure: $e');
    }
  }
}

final Provider<AuditLogger> auditLoggerProvider = Provider<AuditLogger>((ref) {
  final db = ref.watch(databaseProvider);
  return AuditLogger(db);
});
