import 'package:drift/drift.dart';

@DataClassName('User')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get googleId => text().unique().named('google_id')();
  TextColumn get email => text().unique()();
  TextColumn get displayName => text().named('display_name')();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get country => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
