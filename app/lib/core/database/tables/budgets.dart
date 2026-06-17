import 'package:drift/drift.dart';
import 'users.dart';
import 'categories.dart';

@DataClassName('Budget')
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get categoryId => text().nullable().references(Categories, #id).named('category_id')();
  TextColumn get period => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get startDate => dateTime().named('start_date')();
  DateTimeColumn get endDate => dateTime().nullable().named('end_date')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
