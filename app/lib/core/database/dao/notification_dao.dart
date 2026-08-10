import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/notifications.dart';

part 'notification_dao.g.dart';

@DriftAccessor(tables: [AppNotifications])
class NotificationDao extends DatabaseAccessor<AppDatabase> with _$NotificationDaoMixin {
  NotificationDao(super.db);

  Future<List<AppNotification>> getNotificationsForUser(String userId) =>
      (select(appNotifications)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Stream<List<AppNotification>> watchNotificationsForUser(String userId) =>
      (select(appNotifications)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<void> insertNotification(AppNotification notif) => into(appNotifications).insert(notif);
  
  Future<AppNotification?> getNotificationById(String id) =>
      (select(appNotifications)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> markAsRead(String id) =>
      (update(appNotifications)..where((t) => t.id.equals(id))).write(const AppNotificationsCompanion(isRead: Value(true)));

  Future<void> markAllAsRead(String userId) =>
      (update(appNotifications)..where((t) => t.userId.equals(userId))).write(const AppNotificationsCompanion(isRead: Value(true)));

  Future<int> deleteNotification(String id) =>
      (delete(appNotifications)..where((t) => t.id.equals(id))).go();

  Future<int> deleteAllNotifications(String userId) =>
      (delete(appNotifications)..where((t) => t.userId.equals(userId))).go();
}
