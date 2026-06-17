import 'package:drift/drift.dart';
import 'users.dart';
import 'accounts.dart';
import 'categories.dart';
import 'payment_methods.dart';

@DataClassName('Transaction')
@TableIndex(name: 'idx_transactions_user_date', columns: {#userId, #date})
@TableIndex(name: 'idx_transactions_category', columns: {#userId, #categoryId})
@TableIndex(name: 'idx_transactions_sync', columns: {#syncStatus})
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get accountId => text().nullable().references(Accounts, #id).named('account_id')();
  TextColumn get categoryId => text().nullable().references(Categories, #id).named('category_id')();
  TextColumn get paymentMethodId => text().nullable().references(PaymentMethods, #id).named('payment_method_id')();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  TextColumn get currency => text()();
  TextColumn get description => text().nullable()();
  TextColumn get merchant => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get source => text()();
  RealColumn get confidenceScore => real().nullable().named('confidence_score')();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false)).named('is_recurring')();
  TextColumn get syncStatus => text().withDefault(const Constant('pending')).named('sync_status')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().nullable().named('deleted_at')();

  @override
  Set<Column> get primaryKey => {id};
}
