import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('TransactionDraft')
class TransactionDrafts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  IntColumn get amount => integer()();
  TextColumn get type => text()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get merchant => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get smsSender => text().nullable().named('sms_sender')();
  TextColumn get cardOrAccount => text().nullable().named('card_or_account')();
  TextColumn get smsBody => text().nullable().named('sms_body')();
  TextColumn get originalSmsId => text().nullable().named('original_sms_id')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
