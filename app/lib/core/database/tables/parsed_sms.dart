import 'package:drift/drift.dart';
import 'raw_sms.dart';

@DataClassName('ParsedSmsEntry')
class ParsedSms extends Table {
  TextColumn get id => text()();
  TextColumn get smsId => text().nullable().references(RawSms, #id).named('sms_id')();
  TextColumn get sender => text().nullable()();
  DateTimeColumn get receivedAt => dateTime().nullable().named('received_at')();
  TextColumn get bankName => text().nullable().named('bank_name')();
  TextColumn get accountType => text().nullable().named('account_type')();
  TextColumn get accountLast4 => text().nullable().named('account_last_4')();
  TextColumn get cardType => text().nullable().named('card_type')();
  TextColumn get merchant => text().nullable()();
  IntColumn get amount => integer().nullable()(); // in cents
  BoolColumn get isDebit => boolean().nullable().named('is_debit')();
  IntColumn get availableBalance => integer().nullable().named('available_balance')(); // in cents
  TextColumn get referenceNumber => text().nullable().named('reference_number')();
  TextColumn get upiId => text().nullable().named('upi_id')();
  TextColumn get paymentMethod => text().nullable().named('payment_method')();
  TextColumn get purpose => text().nullable()();
  IntColumn get billAmount => integer().nullable().named('bill_amount')(); // in cents
  IntColumn get minDue => integer().nullable().named('min_due')(); // in cents
  IntColumn get outstandingAmount => integer().nullable().named('outstanding_amount')(); // in cents
  DateTimeColumn get dueDate => dateTime().nullable().named('due_date')();
  DateTimeColumn get statementDate => dateTime().nullable().named('statement_date')();
  DateTimeColumn get paymentDate => dateTime().nullable().named('payment_date')();
  TextColumn get category => text().nullable()();
  TextColumn get subcategory => text().nullable()();
  TextColumn get transactionType => text().nullable().named('transaction_type')();
  RealColumn get confidenceScore => real().nullable().named('confidence_score')();
  TextColumn get duplicateHash => text().nullable().named('duplicate_hash')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
