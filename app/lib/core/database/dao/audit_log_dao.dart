import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/audit_logs.dart';

part 'audit_log_dao.g.dart';

@DriftAccessor(tables: [AuditLogs])
class AuditLogDao extends DatabaseAccessor<AppDatabase> with _$AuditLogDaoMixin {
  AuditLogDao(super.db);

  Future<void> insertLog(AuditLog log) => into(auditLogs).insert(log);

  Future<List<AuditLog>> getLogsForUser(String userId) =>
      (select(auditLogs)..where((t) => t.userId.equals(userId))..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();

  Future<List<AuditLog>> getLogsByCategory(String category) =>
      (select(auditLogs)..where((t) => t.eventCategory.equals(category))..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();

  Future<int> clearAllLogs(String userId) =>
      (delete(auditLogs)..where((t) => t.userId.equals(userId))).go();
}
