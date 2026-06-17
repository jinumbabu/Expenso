import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/dao/user_dao.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/security/audit_logger.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

// Database Provider
final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// UserDao Provider
final Provider<UserDao> userDaoProvider = Provider<UserDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.userDao;
});

// Secure Storage Provider
final Provider<SecureStorageService> secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// Base URL configuration for development backend
const String baseUrl = 'http://localhost:8000/api/v1';

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
  return AuthNotifier(repo, auditLogger);
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

  AuthNotifier(this._authRepository, this._auditLogger) : super(AuthState.initial()) {
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
        state = AuthState.authenticated(user);
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

  Future<void> logout() async {
    final userId = state.user?.id;
    state = AuthState.loading();
    try {
      await _authRepository.logout();
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
