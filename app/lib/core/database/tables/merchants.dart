import 'package:drift/drift.dart';

@DataClassName('MerchantEntity')
class Merchants extends Table {
  TextColumn get id => text()();
  TextColumn get rawName => text().unique().named('raw_name')();
  TextColumn get cleanName => text().named('clean_name')();
  TextColumn get category => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
