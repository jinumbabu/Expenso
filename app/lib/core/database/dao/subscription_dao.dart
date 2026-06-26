import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/subscriptions.dart';

part 'subscription_dao.g.dart';

@DriftAccessor(tables: [Subscriptions])
class SubscriptionDao extends DatabaseAccessor<AppDatabase> with _$SubscriptionDaoMixin {
  SubscriptionDao(super.db);

  Future<List<Subscription>> getSubscriptionsForUser(String userId) =>
      (select(subscriptions)..where((t) => t.userId.equals(userId))).get();

  Future<List<Subscription>> getActiveSubscriptions(String userId) =>
      (select(subscriptions)..where((t) => t.userId.equals(userId) & t.status.equals('active'))).get();

  Stream<List<Subscription>> watchSubscriptionsForUser(String userId) =>
      (select(subscriptions)..where((t) => t.userId.equals(userId))).watch();

  Future<Subscription?> getSubscriptionById(String id) =>
      (select(subscriptions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertSubscription(Subscription sub) => into(subscriptions).insert(sub);
  Future<bool> updateSubscription(Subscription sub) => update(subscriptions).replace(sub);
  Future<int> deleteSubscription(String id) =>
      (delete(subscriptions)..where((t) => t.id.equals(id))).go();
}
