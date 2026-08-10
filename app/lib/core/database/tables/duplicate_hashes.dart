import 'package:drift/drift.dart';

@DataClassName('DuplicateHash')
class DuplicateHashes extends Table {
  TextColumn get id => text()();
  TextColumn get hash => text().unique()();
  TextColumn get transactionId => text().nullable().named('transaction_id')();
  TextColumn get billId => text().nullable().named('bill_id')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
