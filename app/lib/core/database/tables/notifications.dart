import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('AppNotification')
class AppNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get priority => text()(); // 'low', 'medium', 'high', 'critical'
  BoolColumn get isRead => boolean().named('is_read')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
