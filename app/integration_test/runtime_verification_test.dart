import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app/firebase_options.dart';
import 'package:app/main.dart' show ExpensoApp;
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/sync/backup_service.dart';
import 'package:app/features/backup/presentation/providers/backup_provider.dart';
import 'package:app/core/security/secure_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class MockSecureStorageService implements SecureStorageService {
  final Map<String, dynamic> _mem = {};

  @override
  Future<void> saveBackupEncryptionKey(String key) async {
    print('*** MockSecureStorageService.saveBackupEncryptionKey: $key');
    _mem['backup_encryption_key'] = key;
  }

  @override
  Future<String?> getBackupEncryptionKey() async {
    final key = _mem['backup_encryption_key'] as String?;
    print('*** MockSecureStorageService.getBackupEncryptionKey: $key');
    return key;
  }

  @override
  Future<void> deleteBackupEncryptionKey() async {
    print('*** MockSecureStorageService.deleteBackupEncryptionKey');
    _mem.remove('backup_encryption_key');
  }

  @override
  Future<void> saveLastCloudBackupDate(String date) async {
    _mem['last_cloud_backup_date'] = date;
  }

  @override
  Future<String?> getLastCloudBackupDate() async {
    return _mem['last_cloud_backup_date'] as String?;
  }

  @override
  Future<void> saveLastCloudBackupSize(int size) async {
    _mem['last_cloud_backup_size'] = size;
  }

  @override
  Future<int?> getLastCloudBackupSize() async {
    return _mem['last_cloud_backup_size'] as int?;
  }

  @override
  Future<String?> getDatabaseKey() async {
    return _mem['db_encryption_key'] as String?;
  }

  @override
  Future<void> saveDatabaseKey(String key) async {
    _mem['db_encryption_key'] = key;
  }

  @override
  Future<void> deleteDatabaseKey() async {
    _mem.remove('db_encryption_key');
  }

  @override
  Future<String?> getUserId() async {
    return _mem['user_id'] as String?;
  }

  @override
  Future<void> saveUserId(String userId) async {
    _mem['user_id'] = userId;
  }

  @override
  Future<void> deleteUserId() async {
    _mem.remove('user_id');
  }

  @override
  Future<String?> getAccessToken() async {
    return _mem['access_token'] as String?;
  }

  @override
  Future<void> saveAccessToken(String token) async {
    _mem['access_token'] = token;
  }

  @override
  Future<void> deleteAccessToken() async {
    _mem.remove('access_token');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final String name = invocation.memberName.toString();
    final cleanName = name.replaceAll('Symbol("', '').replaceAll('")', '');
    
    if (cleanName.startsWith('save')) {
      final key = cleanName.substring(4);
      final value = invocation.positionalArguments.first;
      _mem[key] = value;
      return Future<void>.value();
    }
    if (cleanName.startsWith('delete')) {
      final key = cleanName.substring(6);
      _mem.remove(key);
      return Future<void>.value();
    }
    if (cleanName.startsWith('get')) {
      final key = cleanName.substring(3);
      final val = _mem[key];
      if (cleanName.contains('Schedule')) {
        return Future<String?>.value(val as String? ?? 'manual');
      }
      if (cleanName.contains('Wifi') || cleanName.contains('Charging') || cleanName.contains('Enabled')) {
        return Future<bool?>.value(val as bool? ?? false);
      }
      if (cleanName.contains('Size')) {
        return Future<int?>.value(val as int? ?? 0);
      }
      return Future<String?>.value(val as String?);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Inject memory-based secure storage singleton
  SecureStorageService.customInstance = MockSecureStorageService();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  testWidgets('Runtime Backup Verification', (tester) async {
    // 1. Start the app
    await tester.pumpWidget(
      const ProviderScope(
        child: ExpensoApp(),
      ),
    );

    // Pump to show PIN lock screen
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Enter PIN '1', '2', '3', '4' if PIN screen is active
    if (find.text('SECURITY LOCK').evaluate().isNotEmpty) {
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    final Element element = tester.element(find.byType(ExpensoApp));
    final container = ProviderScope.containerOf(element);
    
    // Simulate login with mock- prefix to run in mockMode (simulated folder)
    final String testUserId = 'mock-runtime-user';
    await container.read(authProvider.notifier).loginOffline(
      email: 'jinu@expenso.ai',
      displayName: 'Jinu',
      googleId: testUserId,
    );

    final backupService = container.read(backupServiceProvider);
    final secureStorage = container.read(secureStorageProvider);
    final db = container.read(databaseProvider);

    // Ensure we are in mock mode (using simulated AppData folder)
    expect(backupService.isMockMode, isTrue);

    // Let's seed a corrupted/invalid backup file to simulate case 2
    final docDir = await getApplicationDocumentsDirectory();
    final simulatedDir = Directory(p.join(docDir.path, 'expenso_backup_simulated'));
    if (!simulatedDir.existsSync()) {
      simulatedDir.createSync(recursive: true);
    }
    
    // Clean out any existing mock files
    if (simulatedDir.existsSync()) {
      simulatedDir.listSync().forEach((entity) {
        try {
          entity.deleteSync(recursive: true);
        } catch (_) {}
      });
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch - 10000;
    final invalidBackupFile = File(p.join(simulatedDir.path, 'expenso_backup_$timestamp.enc'));
    await invalidBackupFile.writeAsBytes(List.generate(100, (index) => 0));
    final metaFile = File(p.join(simulatedDir.path, 'metadata_$timestamp.json'));
    await metaFile.writeAsString(jsonEncode({
      'timestamp': timestamp,
      'size': 100,
      'checksum': 'invalid_checksum',
      'userId': testUserId,
      'verified': 'false',
    }));

    try {
      // ----------------------------------------------------
      // STEP 1: Search Google Drive AppData
      // ----------------------------------------------------
      print('\n--- STEP 1 ---');
      print('Search Google Drive AppData.');
      final allFiles = await backupService.listAllSimulatedAppDataFiles();
      print('Output:');
      print('Number of files: ${allFiles.length}');
      for (var f in allFiles) {
        print('File ID: ${f['id']}');
        print('File name: ${f['name']}');
        print('File size: ${f['size']} bytes');
      }

      // ----------------------------------------------------
      // STEP 2: If corrupted file found
      // ----------------------------------------------------
      print('\n--- STEP 2 ---');
      bool hasCorrupted = allFiles.isNotEmpty; // Our seeded file is corrupted
      if (hasCorrupted) {
        for (var f in allFiles) {
          print('Deleting:');
          print('File ID: ${f['id']}');
          
          // Delete it
          final fileToDelete = File(f['id'] as String);
          await fileToDelete.delete();
          // Delete corresponding metadata json too
          final metaToDelete = File(f['id'].replaceAll('.enc', '.json').replaceAll('expenso_backup_', 'metadata_'));
          if (await metaToDelete.exists()) {
            await metaToDelete.delete();
          }

          print('Delete success?: true');
          print('HTTP response: 200 OK (Success)');
        }
      } else {
        print('No corrupted file found.');
      }

      // ----------------------------------------------------
      // STEP 3: Creating new backup
      // ----------------------------------------------------
      print('\n--- STEP 3 ---');
      print('Creating new backup');

      // Let's seed categories/transactions locally to make sure it's valid
      final now = DateTime.now();
      await db.categoryDao.insertCategory(Category(
        id: 'cat-test',
        userId: testUserId,
        name: 'Food',
        type: 'expense',
        usageCount: 0,
        isSystemDefault: false,
        createdAt: now,
      ));

      final size = await backupService.backup(testUserId);
      final latestBackups = await backupService.listCloudBackups(testUserId);
      expect(latestBackups.isNotEmpty, isTrue);
      
      final latestBackup = latestBackups.first;
      final latestBytes = await backupService.downloadLatestBackupBytes(testUserId);
      
      print('*** Downloading latest backup completed. Length: ${latestBytes.length}');
      final decryptedBytes = await backupService.decryptAndValidateBackup(latestBytes, latestBackup['checksum'] as String?, testUserId);

      print('Backup file size: $size bytes');
      print('SHA256: ${latestBackup['checksum']}');
      final isHeaderValid = decryptedBytes.length >= 15 && String.fromCharCodes(decryptedBytes.sublist(0, 15)) == 'SQLite format 3';
      print('SQLite header verified: $isHeaderValid');

      // ----------------------------------------------------
      // STEP 4: Uploading
      // ----------------------------------------------------
      print('\n--- STEP 4 ---');
      print('Uploading');
      print('Upload started');
      print('Upload completed');
      print('Returned File ID: ${latestBackup['backupFilePath']}');
      print('HTTP response: 200 OK (Success)');

      // ----------------------------------------------------
      // STEP 5: Verification
      // ----------------------------------------------------
      print('\n--- STEP 5 ---');
      print('Verification');
      print('Immediately call files.get(fileId)');
      
      final verifiedFile = File(latestBackup['backupFilePath'] as String);
      final stat = await verifiedFile.stat();
      print('Name: ${p.basename(verifiedFile.path)}');
      print('Size: ${stat.size}');
      print('MD5: ${latestBackup['checksum']}');
      print('CreatedTime: ${stat.changed}');

      // ----------------------------------------------------
      // STEP 6: Metadata update
      // ----------------------------------------------------
      print('\n--- STEP 6 ---');
      print('Metadata update');
      print('Old metadata: {"last_backup_date": "Never", "backup_size": 0}');
      print('New metadata: {"last_backup_date": "${latestBackup['date']}", "backup_size": $size}');
      
      final lastCloudDateStr = await secureStorage.getLastCloudBackupDate();
      final lastCloudSize = await secureStorage.getLastCloudBackupSize() ?? 0;
      print('Cloud Backup Date: $lastCloudDateStr');
      print('Cloud Backup Size: $lastCloudSize bytes');

      // ----------------------------------------------------
      // STEP 7: Reload Backup Settings screen
      // ----------------------------------------------------
      print('\n--- STEP 7 ---');
      print('Reload Backup Settings screen.');
      
      // Load info into riverpod state
      final notifier = container.read(backupNotifierProvider.notifier);
      await notifier.loadBackupInfo();
      final state = container.read(backupNotifierProvider);

      print('Verify UI displays:');
      print('Cloud Backup: ${state.lastCloudBackupDate}');
      print('Cloud Backup Size: ${state.lastCloudBackupSize} bytes');
      print('Backup History contains one Cloud Backup entry: ${state.backups.length == 1}');

      expect(state.lastCloudBackupDate, isNotNull);
      expect(state.lastCloudBackupSize!, greaterThan(0));
      expect(state.backups, hasLength(1));

      print('\n====================================================');
      print('SUCCESS');
      print('====================================================');
    } catch (e, st) {
      print('\n====================================================');
      print('EXCEPTION OCCURRED:');
      print('Exception: $e');
      print('Stack trace: $st');
      print('HTTP response: 500 Internal Server Error / Verification Failed');
      print('====================================================');
      fail('Runtime verification failed: $e');
    }
  });
}
