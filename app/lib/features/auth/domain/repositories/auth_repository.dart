import '../../../../core/database/app_database.dart';

abstract class AuthRepository {
  // Local DB CRUD
  Future<User?> getUserById(String id);
  Future<User?> getUserByEmail(String email);
  Future<void> createUser(User user);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String id);

  // Auth Operations
  Future<User?> loginWithGoogle(String googleToken);
  Future<void> logout();
  Future<User?> getCurrentSessionUser();
  Future<bool> isSessionValid();
}
