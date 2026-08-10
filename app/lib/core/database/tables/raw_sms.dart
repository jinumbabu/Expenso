import 'package:drift/drift.dart';

@DataClassName('RawSmsEntry')
class RawSms extends Table {
  TextColumn get id => text()();
  TextColumn get body => text()();
  TextColumn get sender => text()();
  DateTimeColumn get receivedAt => dateTime().named('received_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
