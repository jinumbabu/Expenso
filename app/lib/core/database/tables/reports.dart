import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('FinancialReport')
class FinancialReports extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get type => text()(); // 'daily', 'weekly', or 'monthly'
  TextColumn get summaryText => text().named('summary_text')();
  TextColumn get jsonPayload => text().named('json_payload')();
  TextColumn get exportedFilePath => text().nullable().named('exported_file_path')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
