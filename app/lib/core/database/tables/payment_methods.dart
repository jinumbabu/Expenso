import 'package:drift/drift.dart';
import 'users.dart';
import 'accounts.dart';

@DataClassName('PaymentMethod')
class PaymentMethods extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get accountId => text().nullable().references(Accounts, #id).named('account_id')();
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get usageCount => integer().withDefault(const Constant(0)).named('usage_count')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
