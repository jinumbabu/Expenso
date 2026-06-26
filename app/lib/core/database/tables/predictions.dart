import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('FinancialPrediction')
class FinancialPredictions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  DateTimeColumn get targetDate => dateTime().named('target_date')();
  IntColumn get predictedBalance => integer().named('predicted_balance')();
  IntColumn get predictedExpenses => integer().named('predicted_expenses')();
  RealColumn get confidence => real()();
  TextColumn get metricPayload => text().named('metric_payload')(); // Extra metrics in JSON format
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
