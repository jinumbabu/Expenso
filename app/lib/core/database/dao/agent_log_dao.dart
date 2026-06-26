import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/agent_logs.dart';

part 'agent_log_dao.g.dart';

@DriftAccessor(tables: [AgentLogs])
class AgentLogDao extends DatabaseAccessor<AppDatabase> with _$AgentLogDaoMixin {
  AgentLogDao(super.db);

  Future<List<AgentLog>> getLogs(int limit) =>
      (select(agentLogs)..orderBy([(t) => OrderingTerm.desc(t.timestamp)])..limit(limit)).get();

  Future<void> insertLog(AgentLog log) => into(agentLogs).insert(log);
  
  Future<void> clearAllLogs() => delete(agentLogs).go();
}
