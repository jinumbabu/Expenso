import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('UnrecognizedMessage')
class UnrecognizedMessages extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get sender => text().nullable()();
  TextColumn get body => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get failureReason => text().nullable().named('failure_reason')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
