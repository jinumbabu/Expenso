import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/dao/user_dao.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/security/audit_logger.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

import '../../../../core/sync/firestore_sync_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/balance_engine.dart';
import '../../../dashboard/presentation/providers/hide_balance_provider.dart';
import '../../../../core/services/settings_provider.dart';

// Database Provider
final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());

  // Recalculate balances on startup to repair any out-of-sync balances
  Future.microtask(() async {
    try {
      final txCount = await db.customSelect('SELECT COUNT(*) as c FROM transactions').getSingle();
      final accCount = await db.customSelect('SELECT COUNT(*) as c FROM accounts').getSingle();
      final userCount = await db.customSelect('SELECT COUNT(*) as c FROM users').getSingle();
      
      print('STARTUP_DB_DIAGNOSTICS: transactionsCount=${txCount.read<int>('c')}, accountsCount=${accCount.read<int>('c')}, usersCount=${userCount.read<int>('c')}');
      
      final txUsers = await db.customSelect('SELECT DISTINCT user_id FROM transactions').get();
      print('  Transaction User IDs: ${txUsers.map((r) => r.read<String>('user_id')).toList()}');
      
      final accUsers = await db.customSelect('SELECT DISTINCT user_id FROM accounts').get();
      print('  Account User IDs: ${accUsers.map((r) => r.read<String>('user_id')).toList()}');
      
      final usersList = await db.customSelect('SELECT id, display_name FROM users').get();
      print('  Registered Users: ${usersList.map((r) => "${r.read<String>('id')}:${r.read<String>('display_name')}").toList()}');

      await BalanceEngine(db).recalculateAllBalances();
    } catch (e) {
      debugPrint('Error during startup balance recalculation: $e');
    }
  });

  return db;
});

// UserDao Provider
final Provider<UserDao> userDaoProvider = Provider<UserDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.userDao;
});



// Google Sign-In Provider
final Provider<GoogleSignIn> googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    serverClientId: '115928479310-7rn9sc6ba9j27e40aohbpoovdd43mlbq.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
      'openid',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );
});

// Base URL configuration for development backend
final String baseUrl = _getBaseUrl();

String _getBaseUrl() {
  if (kReleaseMode) {
    return 'https://api.expenso.app/api/v1';
  }
  if (kIsWeb) {
    return 'http://localhost:8000/api/v1';
  }
  try {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
  } catch (_) {}
  return 'http://localhost:8000/api/v1';
}

// Auth Interceptor Provider
final Provider<AuthInterceptor> authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthInterceptor(
    secureStorage: secureStorage,
    baseUrl: baseUrl,
    onLogoutRequired: () {
      ref.read(authProvider.notifier).forceLogoutState();
    },
  );
});

// Dio Client Provider
final Provider<DioClient> dioClientProvider = Provider<DioClient>((ref) {
  final interceptor = ref.watch(authInterceptorProvider);
  return DioClient(baseUrl: baseUrl, authInterceptor: interceptor);
});

// Remote DataSource Provider
final Provider<AuthRemoteDataSource> authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(client.dio);
});

// AuthRepository Provider
final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  final userDao = ref.watch(userDaoProvider);
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(userDao, remoteDataSource, secureStorage);
});

// AuthState Notifier Provider
final StateNotifierProvider<AuthNotifier, AuthState> authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final auditLogger = ref.watch(auditLoggerProvider);
  final notifier = AuthNotifier(repo, auditLogger, ref);
  
  // ignore: deprecated_member_use
  ref.listenSelf((previous, next) {
    if (previous?.status != AuthStatus.authenticated && next.status == AuthStatus.authenticated && next.user != null) {
      final userId = next.user!.id;
      Future.microtask(() async {
        // Restore user profile from Cloud Firestore automatically
        await ref.read(firestoreSyncServiceProvider).syncUserProfileFromCloud(userId);
        // Refresh session to apply restored profile name and preferences locally
        await notifier.checkSession();
      });
      ref.read(firestoreSyncServiceProvider).startRealTimeSync(userId);
      ref.read(notificationServiceProvider).checkUpcomingBillsAndSubscriptions(userId);
      ref.read(notificationServiceProvider).checkGoalProgressReminders(userId);
    } else if (next.status == AuthStatus.unauthenticated) {
      ref.read(firestoreSyncServiceProvider).stopRealTimeSync();
    }
  });

  return notifier;
});

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(User user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated({String? error}) => AuthState(status: AuthStatus.unauthenticated, errorMessage: error);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final AuditLogger _auditLogger;
  final Ref _ref;

  AuthNotifier(this._authRepository, this._auditLogger, this._ref) : super(AuthState.initial()) {
    checkSession();
  }

  Future<void> checkSession() async {
    try {
      final user = await _authRepository.getCurrentSessionUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> loginWithGoogle(String googleToken) async {
    state = AuthState.loading();
    try {
      final user = await _authRepository.loginWithGoogle(googleToken);
      if (user != null) {
        final secureStorage = _ref.read(secureStorageProvider);
        await secureStorage.write('privacy_accepted', 'true');
        await secureStorage.write('privacy_accepted_version', '1.0');
        await secureStorage.write('privacy_accepted_at_${user.id}', DateTime.now().toIso8601String());
        await secureStorage.write('privacy_accepted_user_${user.id}', user.id);

        // Register account globally
        try {
          final listStr = await secureStorage.read('registered_accounts');
          List<dynamic> accounts = [];
          if (listStr != null) {
            accounts = jsonDecode(listStr);
          }
          if (!accounts.any((a) => a['id'] == user.id)) {
            accounts.add({
              'id': user.id,
              'email': user.email,
              'displayName': user.displayName,
              'photoUrl': user.photoUrl,
            });
            await secureStorage.write('registered_accounts', jsonEncode(accounts));
          }
        } catch (_) {}

        state = AuthState.authenticated(user);
        _ref.invalidate(databaseProvider);
        await _auditLogger.logEvent(
          userId: user.id,
          eventType: 'auth_login',
          eventCategory: 'authentication',
          description: 'User successfully logged in via Google OAuth.',
          metadata: {'google_id': user.googleId, 'email': user.email},
        );
      } else {
        state = AuthState.unauthenticated(error: 'Google authentication failed');
        await _auditLogger.logEvent(
          userId: null,
          eventType: 'auth_login_failed',
          eventCategory: 'authentication',
          description: 'Google authentication failed: user profile is empty.',
        );
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
      await _auditLogger.logEvent(
        userId: null,
        eventType: 'auth_login_failed',
        eventCategory: 'authentication',
        description: 'Google authentication failed with exception: ${e.toString()}',
      );
    }
  }

  Future<void> loginOffline({
    String? email,
    String? displayName,
    String? googleId,
  }) async {
    state = AuthState.loading();
    try {
      final user = await _authRepository.loginOffline(
        email: email,
        displayName: displayName,
        googleId: googleId,
      );
      if (user != null) {
        final secureStorage = _ref.read(secureStorageProvider);
        await secureStorage.write('privacy_accepted', 'true');
        await secureStorage.write('privacy_accepted_version', '1.0');
        await secureStorage.write('privacy_accepted_at_${user.id}', DateTime.now().toIso8601String());
        await secureStorage.write('privacy_accepted_user_${user.id}', user.id);

        // Register account globally
        try {
          final listStr = await secureStorage.read('registered_accounts');
          List<dynamic> accounts = [];
          if (listStr != null) {
            accounts = jsonDecode(listStr);
          }
          if (!accounts.any((a) => a['id'] == user.id)) {
            accounts.add({
              'id': user.id,
              'email': user.email,
              'displayName': user.displayName,
              'photoUrl': user.photoUrl,
            });
            await secureStorage.write('registered_accounts', jsonEncode(accounts));
          }
        } catch (_) {}

        state = AuthState.authenticated(user);
        _ref.invalidate(databaseProvider);
        await _auditLogger.logEvent(
          userId: user.id,
          eventType: 'auth_login_offline',
          eventCategory: 'authentication',
          description: 'User logged in via Offline Mode.',
          metadata: {'email': user.email},
        );
      } else {
        state = AuthState.unauthenticated(error: 'Offline login failed');
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> switchAccount(String targetUserId) async {
    state = AuthState.loading();
    try {
      _ref.read(firestoreSyncServiceProvider).stopRealTimeSync();

      final secureStorage = _ref.read(secureStorageProvider);
      await secureStorage.saveUserId(targetUserId);

      final user = await _authRepository.getCurrentSessionUser();
      
      _ref.invalidate(databaseProvider);
      _ref.read(isUnlockedProvider.notifier).state = false;
      _ref.invalidate(appSettingsProvider);
      _ref.invalidate(hideBalanceProvider);

      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated(error: 'Failed to switch account session.');
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> removeAccount(String targetUserId) async {
    try {
      final secureStorage = _ref.read(secureStorageProvider);
      final listStr = await secureStorage.read('registered_accounts');
      if (listStr != null) {
        List<dynamic> accounts = jsonDecode(listStr);
        accounts.removeWhere((a) => a['id'] == targetUserId);
        await secureStorage.write('registered_accounts', jsonEncode(accounts));
      }

      final supportDir = await getApplicationSupportDirectory();
      final dbFile = File(p.join(supportDir.path, 'expenso_database_$targetUserId.sqlite'));
      final walFile = File(p.join(supportDir.path, 'expenso_database_$targetUserId.sqlite-wal'));
      final shmFile = File(p.join(supportDir.path, 'expenso_database_$targetUserId.sqlite-shm'));

      if (dbFile.existsSync()) dbFile.deleteSync();
      if (walFile.existsSync()) walFile.deleteSync();
      if (shmFile.existsSync()) shmFile.deleteSync();

      await secureStorage.deleteDatabaseKey(userId: targetUserId);
      await secureStorage.deleteBackupEncryptionKey(userId: targetUserId);
      await secureStorage.delete('onboarding_completed_$targetUserId');
      await secureStorage.delete('pin_hash_$targetUserId');
      await secureStorage.delete('pin_salt_$targetUserId');

      _ref.invalidate(registeredAccountsProvider);
    } catch (_) {}
  }

  Future<void> logout() async {
    final userId = state.user?.id;
    state = AuthState.loading();
    try {
      // 1. Invalidate sync and other listeners
      _ref.read(firestoreSyncServiceProvider).stopRealTimeSync();

      // 2. Repository sign-out (clears secure storage tokens)
      await _authRepository.logout();

      // 3. Native Firebase & Google sign-out
      try {
        await fb.FirebaseAuth.instance.signOut();
        await _ref.read(googleSignInProvider).signOut();
      } catch (e) {
        debugPrint('Error signing out of Google/Firebase: $e');
      }

      // 4. Invalidate database to close active connection
      _ref.invalidate(databaseProvider);

      // 5. Invalidate settings, lock state, etc.
      _ref.read(isUnlockedProvider.notifier).state = false;
      _ref.read(onboardingCompletedProvider.notifier).reset();
      _ref.invalidate(appSettingsProvider);
      _ref.invalidate(hideBalanceProvider);

      state = AuthState.unauthenticated();

      if (userId != null) {
        await _auditLogger.logEvent(
          userId: userId,
          eventType: 'auth_logout',
          eventCategory: 'authentication',
          description: 'User successfully logged out of the session.',
        );
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  void forceLogoutState() {
    state = AuthState.unauthenticated();
  }
}

final isUnlockedProvider = StateProvider<bool>((ref) => false);

final onboardingCompletedProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final auth = ref.watch(authProvider);
  return OnboardingNotifier(secureStorage, auth.user?.id);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final SecureStorageService _secureStorage;
  final String? _userId;

  OnboardingNotifier(this._secureStorage, this._userId) : super(true) {
    _load();
  }

  Future<void> _load() async {
    if (_userId == null) {
      state = true;
      return;
    }
    final completed = await _secureStorage.read('onboarding_completed_$_userId');
    state = completed == 'true';
  }

  Future<void> completeOnboarding() async {
    if (_userId == null) return;
    state = true;
    await _secureStorage.write('onboarding_completed_$_userId', 'true');
  }

  void reset() {
    state = false;
  }
}

final registeredAccountsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final secureStorage = ref.watch(secureStorageProvider);
  final str = await secureStorage.read('registered_accounts');
  if (str == null) return [];
  try {
    final list = jsonDecode(str) as List;
    return list.map((item) => Map<String, dynamic>.from(item)).toList();
  } catch (_) {
    return [];
  }
});
