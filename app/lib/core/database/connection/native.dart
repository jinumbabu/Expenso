import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../security/secure_storage_service.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final supportDir = await getApplicationSupportDirectory();
    final file = File(p.join(supportDir.path, 'expenso_database.sqlite'));

    // Resolve key from secure storage
    final secureStorage = SecureStorageService();
    String? key = await secureStorage.getDatabaseKey();
    if (key == null) {
      // Generate a random 32-character key
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      key = base64UrlEncode(values);
      await secureStorage.saveDatabaseKey(key);
    }

    return NativeDatabase(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$key';");
      },
    );
  });
}
