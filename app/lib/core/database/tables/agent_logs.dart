import 'package:drift/drift.dart';

@DataClassName('AgentLog')
class AgentLogs extends Table {
  TextColumn get id => text()();
  TextColumn get agentName => text().named('agent_name')();
  TextColumn get actionType => text().named('action_type')();
  TextColumn get decisionDescription => text().named('decision_description')();
  RealColumn get confidenceScore => real().named('confidence_score')();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
