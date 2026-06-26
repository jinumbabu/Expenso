import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('Goal')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get title => text()();
  IntColumn get targetAmount => integer().named('target_amount')();
  IntColumn get currentAmount => integer().named('current_amount')();
  DateTimeColumn get targetDate => dateTime().named('target_date')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
