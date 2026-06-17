import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('AiMemoryItem')
class AiMemories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get memoryType => text().named('memory_type')(); // 'preference', 'behavioral', 'conversational'
  TextColumn get memoryKey => text().named('memory_key')();
  TextColumn get memoryValue => text().named('memory_value')();
  RealColumn get confidence => real().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable().named('expires_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get lastAccessedAt => dateTime().nullable().named('last_accessed_at')();

  @override
  Set<Column> get primaryKey => {id};
}
