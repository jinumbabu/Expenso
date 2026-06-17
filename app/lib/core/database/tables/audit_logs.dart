import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('AuditLog')
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable().references(Users, #id).named('user_id')();
  TextColumn get eventType => text().named('event_type')(); // e.g., 'auth_login', 'backup_created'
  TextColumn get eventCategory => text().named('event_category')(); // e.g., 'authentication', 'backup'
  TextColumn get description => text()();
  TextColumn get metadata => text().nullable()(); // JSON string with extra details
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
