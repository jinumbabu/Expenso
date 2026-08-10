import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('Account')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get balance => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false)).named('is_default')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  // Customization & general fields
  TextColumn get bankName => text().nullable().named('bank_name')();
  IntColumn get openingBalance => integer().nullable().named('opening_balance')();
  TextColumn get currency => text().nullable()();
  TextColumn get colorTheme => text().nullable().named('color_theme')();
  TextColumn get icon => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().nullable().named('is_active')();

  // Credit Card specific fields
  IntColumn get creditLimit => integer().nullable().named('credit_limit')();
  IntColumn get availableCredit => integer().nullable().named('available_credit')();
  IntColumn get outstandingBalance => integer().nullable().named('outstanding_balance')();
  IntColumn get statementDate => integer().nullable().named('statement_date')(); // e.g. 15th
  IntColumn get paymentDueDate => integer().nullable().named('payment_due_date')(); // e.g. 5th
  IntColumn get minAmountDue => integer().nullable().named('min_amount_due')();
  IntColumn get totalAmountDue => integer().nullable().named('total_amount_due')();
  IntColumn get lastPayment => integer().nullable().named('last_payment')();
  DateTimeColumn get nextDueDate => dateTime().nullable().named('next_due_date')();
  TextColumn get paymentStatus => text().nullable().named('payment_status')(); // paid, unpaid, overdue
  BoolColumn get autoPay => boolean().nullable().named('auto_pay')();
  BoolColumn get isEstimated => boolean().withDefault(const Constant(false)).named('is_estimated')();
  TextColumn get last4Digits => text().nullable().named('last_4_digits')();
  TextColumn get statementCycle => text().nullable().named('statement_cycle')();
  BoolColumn get enableBillReminder => boolean().nullable().withDefault(const Constant(true)).named('enable_bill_reminder')();
  BoolColumn get enableSmsTracking => boolean().nullable().withDefault(const Constant(true)).named('enable_sms_tracking')();

  // Verification & Mismatch columns
  IntColumn get verifiedBalance => integer().nullable().named('verified_balance')();
  IntColumn get calculatedBalance => integer().nullable().named('calculated_balance')();
  IntColumn get importedBalance => integer().nullable().named('imported_balance')();
  IntColumn get lastSyncedBalance => integer().nullable().named('last_synced_balance')();
  DateTimeColumn get verifiedAt => dateTime().nullable().named('verified_at')();
  BoolColumn get hasMismatch => boolean().nullable().withDefault(const Constant(false)).named('has_mismatch')();
  IntColumn get mismatchExpected => integer().nullable().named('mismatch_expected')();
  IntColumn get mismatchImported => integer().nullable().named('mismatch_imported')();
  IntColumn get sortOrder => integer().nullable().named('sort_order')();

  @override
  Set<Column> get primaryKey => {id};
}
