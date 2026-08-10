import 'package:drift/drift.dart';
import 'users.dart';
import 'accounts.dart';
import 'transactions.dart';

@DataClassName('Bill')
class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get accountId => text().nullable().references(Accounts, #id).named('account_id')();
  TextColumn get title => text()();
  IntColumn get amount => integer()(); // in cents
  IntColumn get minDue => integer().nullable().named('min_due')(); // in cents
  DateTimeColumn get dueDate => dateTime().nullable().named('due_date')();
  DateTimeColumn get statementDate => dateTime().nullable().named('statement_date')();
  TextColumn get status => text()(); // generated, pending, reminder, payment_pending, payment_detected, paid, archived
  TextColumn get billingCycle => text().nullable().named('billing_cycle')();
  TextColumn get paymentTransactionId => text().nullable().references(Transactions, #id).named('payment_transaction_id')();
  TextColumn get paymentSourceAccountId => text().nullable().references(Accounts, #id).named('payment_source_account_id')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
