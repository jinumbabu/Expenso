import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('AiLearning')
class AiLearnings extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get patternKey => text().named('pattern_key')(); // e.g. "merchant:zomato"
  TextColumn get userValue => text().named('user_value')(); // e.g. "Food"
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
