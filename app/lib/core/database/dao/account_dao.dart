import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/accounts.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<List<Account>> getAccountsForUser(String userId) =>
      (select(accounts)..where((t) => t.userId.equals(userId))).get();

  Future<Account?> getAccountById(String id) =>
      (select(accounts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Account?> getDefaultAccount(String userId) =>
      (select(accounts)..where((t) => t.userId.equals(userId) & t.isDefault.equals(true))).getSingleOrNull();

  Future<void> insertAccount(Account account) => into(accounts).insert(account);
  Future<bool> updateAccount(Account account) => update(accounts).replace(account);
  Future<int> deleteAccount(String id) =>
      (delete(accounts)..where((t) => t.id.equals(id))).go();
}
