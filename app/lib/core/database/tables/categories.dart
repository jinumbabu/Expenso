import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('Category')
@TableIndex(name: 'idx_categories_usage', columns: {#userId, #usageCount})
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get usageCount => integer().withDefault(const Constant(0)).named('usage_count')();
  DateTimeColumn get lastUsedAt => dateTime().nullable().named('last_used_at')();
  BoolColumn get isSystemDefault => boolean().withDefault(const Constant(false)).named('is_system_default')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
