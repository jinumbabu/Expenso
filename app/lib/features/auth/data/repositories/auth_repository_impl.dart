import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/dao/user_dao.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/security/secure_storage_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final UserDao _userDao;
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;

  AuthRepositoryImpl(
    this._userDao,
    this._remoteDataSource,
    this._secureStorage,
  );

  Future<User?> _resolveUserDisplayName(User? user) async {
    if (user == null) return null;
    
    // 1. Check custom name in SecureStorage
    final customName = await _secureStorage.getCustomDisplayName(userId: user.id);
    if (customName != null && customName.isNotEmpty) {
      return user.copyWith(displayName: customName);
    }
    
    // 2. Check if user already has a valid name (not generic/placeholder)
    if (user.displayName != null && user.displayName!.isNotEmpty && user.displayName != 'Google User' && user.displayName != 'Offline User' && user.displayName != 'Test User (Mock)') {
      return user;
    }
    
    // 3. Fallback to Email username
    if (user.email != null && user.email!.isNotEmpty) {
      final username = user.email!.split('@')[0];
      if (username.isNotEmpty) {
        return user.copyWith(displayName: username);
      }
    }
    
    // 4. Default to Unknown User
    return user.copyWith(displayName: 'Unknown User');
  }

  @override
  Future<User?> getUserById(String id) async {
    final user = await _userDao.getUserById(id);
    return await _resolveUserDisplayName(user);
  }

  @override
  Future<User?> getUserByEmail(String email) => _userDao.getUserByEmail(email);

  @override
  Future<void> createUser(User user) => _userDao.insertUser(user);

  @override
  Future<void> updateUser(User user) => _userDao.updateUser(user);

  @override
  Future<void> deleteUser(String id) => _userDao.deleteUser(id);

  @override
  Future<User?> loginWithGoogle(String googleToken) async {
    if (!kReleaseMode && (googleToken == 'mock-google-id-token' || googleToken.startsWith('mock-'))) {
      const mockUserId = 'mock_user_123';
      final localUser = User(
        id: mockUserId,
        googleId: googleToken,
        email: 'testuser@expenso.app',
        displayName: 'Test User (Mock)',
        currency: 'INR',
        country: 'IN',
        photoUrl: 'https://via.placeholder.com/150',
        lastLogin: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _secureStorage.saveUserId(mockUserId);
      await _secureStorage.saveAccessToken('mock_access_token');
      await _secureStorage.saveRefreshToken('mock_refresh_token');

      final existingUser = await _userDao.getUserById(mockUserId);
      if (existingUser != null) {
        await _userDao.updateUser(localUser);
      } else {
        await _userDao.insertUser(localUser);
      }
      return await _resolveUserDisplayName(localUser);
    }

    try {
      final authData = await _remoteDataSource.loginWithGoogle(googleToken);
      if (authData['success'] == true) {
        final tokens = authData['data'];
        final accessToken = tokens['access_token'] as String;
        final refreshToken = tokens['refresh_token'] as String;
        
        await _secureStorage.saveAccessToken(accessToken);
        await _secureStorage.saveRefreshToken(refreshToken);

        final profileData = await _remoteDataSource.getUserProfile();
        final userId = profileData['id'] as String;
        final displayName = profileData['name'] as String;
        final email = authData['data']['user']['email'] as String;
        final currency = profileData['currency'] as String? ?? 'INR';
        final country = profileData['country'] as String?;
        final photoUrl = profileData['photo_url'] as String? ?? (fb.FirebaseAuth.instance.currentUser?.photoURL);

        await _secureStorage.saveUserId(userId);

        final localUser = User(
          id: userId,
          googleId: googleToken,
          email: email,
          displayName: displayName,
          currency: currency,
          country: country,
          photoUrl: photoUrl,
          lastLogin: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final existingUser = await _userDao.getUserById(userId);
        if (existingUser != null) {
          await _userDao.updateUser(localUser);
        } else {
          await _userDao.insertUser(localUser);
        }

        return await _resolveUserDisplayName(localUser);
      }
    } catch (e) {
      // Bypass API server if Firebase authentication is successful (online sync should run)
      final firebaseUser = fb.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final userId = firebaseUser.uid;
        final displayName = firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'Google User';
        final email = firebaseUser.email ?? 'googleuser@expenso.app';
        final photoUrl = firebaseUser.photoURL;

        await _secureStorage.saveUserId(userId);
        await _secureStorage.saveAccessToken('firebase_access_token_$userId');
        await _secureStorage.saveRefreshToken('firebase_refresh_token_$userId');

        final localUser = User(
          id: userId,
          googleId: googleToken,
          email: email,
          displayName: displayName,
          currency: 'INR',
          country: 'IN',
          photoUrl: photoUrl,
          lastLogin: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final existingUser = await _userDao.getUserById(userId);
        if (existingUser != null) {
          await _userDao.updateUser(localUser);
        } else {
          await _userDao.insertUser(localUser);
        }
        return await _resolveUserDisplayName(localUser);
      }
      rethrow;
    }
    return null;
  }

  @override
  Future<User?> loginOffline({
    String? email,
    String? displayName,
    String? googleId,
  }) async {
    final String offlineUserId = googleId ?? 'offline_user_999';
    final localUser = User(
      id: offlineUserId,
      googleId: googleId ?? 'offline_google_id',
      email: email ?? 'offline@expenso.app',
      displayName: displayName ?? 'Offline User',
      currency: 'INR',
      country: 'IN',
      photoUrl: null,
      lastLogin: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _secureStorage.saveUserId(offlineUserId);
    await _secureStorage.saveAccessToken('offline_access_token');
    await _secureStorage.saveRefreshToken('offline_refresh_token');

    final existingUser = await _userDao.getUserById(offlineUserId);
    if (existingUser != null) {
      await _userDao.updateUser(localUser);
    } else {
      await _userDao.insertUser(localUser);
    }
    return await _resolveUserDisplayName(localUser);
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Ignore failures on logout API request (e.g. offline)
    } finally {
      await _secureStorage.deleteAccessToken();
      await _secureStorage.deleteRefreshToken();
      await _secureStorage.deleteUserId();
      await _secureStorage.deleteGoogleAccessToken();
    }
  }

  @override
  Future<User?> getCurrentSessionUser() async {
    final userId = await _secureStorage.getUserId();
    if (userId == null) return null;
    final user = await _userDao.getUserById(userId);
    return await _resolveUserDisplayName(user);
  }

  @override
  Future<bool> isSessionValid() async {
    final token = await _secureStorage.getAccessToken();
    return token != null;
  }
}
