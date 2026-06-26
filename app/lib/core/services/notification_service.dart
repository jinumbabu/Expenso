import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/app_database.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  AppDatabase? _db;

  NotificationService._internal();

  void setDatabase(AppDatabase db) {
    _db = db;
  }

  Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      if (Platform.isAndroid) {
        await Permission.notification.request();
      }

      await scheduleDailyReminder();
      await scheduleWeeklyReminder();
      await scheduleMonthlyReminder();
    } catch (e) {
      // Fail silently if not supported in dev test setup
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'expenso_alerts',
        'Expenso Alert Notifications',
        channelDescription: 'Alert notifications for budget compliance, bills, and targets.',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: DarwinNotificationDetails(),
      );

      await flutterLocalNotificationsPlugin.show(id, title, body, notificationDetails);
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> sendProactiveAlert(
    String userId, {
    required String title,
    required String body,
    required String priority, // 'low', 'medium', 'high', 'critical'
  }) async {
    // 1. Show local platform notification
    final int notifId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await showNotification(
      id: notifId,
      title: title,
      body: body,
    );

    // 2. Insert into database
    if (_db != null) {
      try {
        final notif = AppNotification(
          id: const Uuid().v4(),
          userId: userId,
          title: title,
          body: body,
          priority: priority,
          isRead: false,
          createdAt: DateTime.now(),
        );
        await _db!.notificationDao.insertNotification(notif);
      } catch (e) {
        // Fail silently
      }
    }
  }

  Future<void> scheduleDailyReminder() async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        999,
        'Expenso Daily Review',
        'Time to log your daily transactions and review today\'s spending insights.',
        _nextInstanceOfNinePM(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expenso_daily_reminder',
            'Expenso Daily Reminders',
            channelDescription: 'Reminding users to log daily expenses.',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Fail silently
    }
  }

  tz.TZDateTime _nextInstanceOfNinePM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 21, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> scheduleWeeklyReminder() async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        998,
        'Weekly Spending Report',
        'Your weekly financial report is ready. Tap to view your insights and savings.',
        _nextInstanceOfSundayEightPM(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expenso_weekly_reminder',
            'Expenso Weekly Reminders',
            channelDescription: 'Reminding users to check weekly summaries.',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      // Fail silently
    }
  }

  tz.TZDateTime _nextInstanceOfSundayEightPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
    while (scheduledDate.weekday != DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    return scheduledDate;
  }

  Future<void> scheduleMonthlyReminder() async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        997,
        'Monthly Financial Report',
        'Welcome to the new month! Review your complete monthly report and budget performance.',
        _nextInstanceOfFirstOfMonthNineAM(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expenso_monthly_reminder',
            'Expenso Monthly Reminders',
            channelDescription: 'Reminding users to check monthly summaries.',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (e) {
      // Fail silently
    }
  }

  tz.TZDateTime _nextInstanceOfFirstOfMonthNineAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, 1, 9, 0);
    if (scheduledDate.isBefore(now)) {
      int nextMonth = now.month + 1;
      int nextYear = now.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      scheduledDate = tz.TZDateTime(tz.local, nextYear, nextMonth, 1, 9, 0);
    }
    return scheduledDate;
  }

  Future<void> checkUpcomingBillsAndSubscriptions(String userId) async {
    if (_db == null) return;
    try {
      final activeSubs = await _db!.subscriptionDao.getActiveSubscriptions(userId);
      final now = DateTime.now();
      for (var sub in activeSubs) {
        final difference = sub.renewalDate.difference(now).inDays;
        if (difference >= 0 && difference <= 3) {
          final String dueText = difference == 0 
              ? 'due today' 
              : 'due in $difference day${difference > 1 ? "s" : ""}';
          
          await sendProactiveAlert(
            userId,
            title: 'Upcoming Bill/Subscription 📅',
            body: 'Your subscription "${sub.title}" (₹${(sub.monthlyCost / 100.0).toStringAsFixed(2)}) is $dueText.',
            priority: difference == 0 ? 'critical' : 'high',
          );
        }
      }
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> checkGoalProgressReminders(String userId) async {
    if (_db == null) return;
    try {
      final goals = await _db!.goalDao.getGoalsForUser(userId);
      final now = DateTime.now();
      for (var goal in goals) {
        final totalCents = goal.targetAmount;
        final currentCents = goal.currentAmount;
        if (totalCents == 0) continue;
        
        final double percent = currentCents / totalCents;
        final daysLeft = goal.targetDate.difference(now).inDays;
        
        if (daysLeft >= 0 && daysLeft <= 7 && percent < 1.0) {
          await sendProactiveAlert(
            userId,
            title: 'Goal Target Approaching! 🎯',
            body: 'Your goal "${goal.title}" target date is in $daysLeft days. You have saved ${(percent * 100).toStringAsFixed(0)}% (₹${(currentCents / 100.0).toStringAsFixed(2)} / ₹${(totalCents / 100.0).toStringAsFixed(2)}).',
            priority: 'high',
          );
        }
      }
    } catch (e) {
      // Fail silently
    }
  }
}

final Provider<NotificationService> notificationServiceProvider = Provider<NotificationService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = NotificationService._instance;
  service.setDatabase(db);
  return service;
});

final notificationsStreamProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return const Stream.empty();
  return db.notificationDao.watchNotificationsForUser(userId);
});
