import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('ChatHistoryItem')
class ChatHistory extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get role => text()(); // 'user' or 'model'
  TextColumn get message => text()();
  TextColumn get aiMode => text().named('ai_mode')(); // 'local', 'hybrid', 'cloud'
  IntColumn get tokenCount => integer().nullable().named('token_count')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
