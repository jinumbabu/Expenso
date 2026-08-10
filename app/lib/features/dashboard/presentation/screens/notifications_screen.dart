import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../sms_parser/presentation/providers/sms_parser_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final draftsAsync = ref.watch(transactionDraftsStreamProvider);
    final auth = ref.watch(authProvider);
    final userId = auth.user?.id;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050E1A), Color(0xFF050505)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Premium Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    if (userId != null) ...[
                      // Mark All Read Button
                      IconButton(
                        icon: const Icon(Icons.mark_chat_read_outlined, color: Color(0xFF00E5FF), size: 20),
                        tooltip: 'Mark all as read',
                        onPressed: () async {
                          final db = ref.read(databaseProvider);
                          await db.notificationDao.markAllAsRead(userId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All notifications marked as read.'),
                                backgroundColor: Color(0xFF0F1A1C),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      // Delete All Button
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFFF3B30), size: 20),
                        tooltip: 'Delete all',
                        onPressed: () => _confirmDeleteAll(context, ref, userId),
                      ),
                    ]
                  ],
                ),
              ),

              const Divider(color: Colors.white10, height: 1),

              // Notifications List
              Expanded(
                child: notificationsAsync.when(
                  data: (notifications) {
                    return draftsAsync.when(
                      data: (drafts) {
                        final pendingDraftsCount = drafts.length;
                        
                        if (notifications.isEmpty && pendingDraftsCount == 0) {
                          return _buildEmptyState();
                        }

                        return _buildNotificationsList(
                          context,
                          ref,
                          notifications,
                          pendingDraftsCount,
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                      error: (err, _) => Center(child: Text('Error loading drafts: $err', style: const TextStyle(color: Colors.redAccent))),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                  error: (err, _) => Center(child: Text('Error loading notifications: $err', style: const TextStyle(color: Colors.redAccent))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  size: 48,
                  color: Color(0xFF0066FF),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'All Caught Up!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No new alerts or pending tasks at this moment. We will notify you when something comes up.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    List<AppNotification> notifications,
    int pendingDraftsCount,
  ) {
    // Separate notifications into Today, Yesterday, earlier
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayNotifs = <AppNotification>[];
    final yesterdayNotifs = <AppNotification>[];
    final earlierNotifs = <AppNotification>[];

    for (var n in notifications) {
      final compareDate = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (compareDate == today) {
        todayNotifs.add(n);
      } else if (compareDate == yesterday) {
        yesterdayNotifs.add(n);
      } else {
        earlierNotifs.add(n);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        // 1. Dynamic Pending drafts card (always in "Today" section if drafts count > 0)
        if (pendingDraftsCount > 0) ...[
          _buildSectionHeader('Today'),
          const SizedBox(height: 8),
          _buildPendingDraftsBanner(context, pendingDraftsCount),
          const SizedBox(height: 16),
        ],

        // 2. Today Section
        if (todayNotifs.isNotEmpty) ...[
          if (pendingDraftsCount == 0) ...[
            _buildSectionHeader('Today'),
            const SizedBox(height: 8),
          ],
          ...todayNotifs.map((n) => _buildNotificationCard(context, ref, n)),
          const SizedBox(height: 16),
        ],

        // 3. Yesterday Section
        if (yesterdayNotifs.isNotEmpty) ...[
          _buildSectionHeader('Yesterday'),
          const SizedBox(height: 8),
          ...yesterdayNotifs.map((n) => _buildNotificationCard(context, ref, n)),
          const SizedBox(height: 16),
        ],

        // 4. Earlier Section
        if (earlierNotifs.isNotEmpty) ...[
          _buildSectionHeader('Earlier'),
          const SizedBox(height: 8),
          ...earlierNotifs.map((n) => _buildNotificationCard(context, ref, n)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildPendingDraftsBanner(BuildContext context, int count) {
    return GestureDetector(
      onTap: () => context.push('/sms-drafts'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF002B24), Color(0xFF0066FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.tealAccent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.textsms_rounded, color: Colors.tealAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending SMS Drafts',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You have $count transaction drafts waiting for approval.',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.tealAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF002B24), size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, AppNotification n) {
    IconData iconData = Icons.info_outline;
    Color priorityColor = const Color(0xFF0066FF);

    switch (n.priority) {
      case 'critical':
        iconData = Icons.report_gmailerrorred_outlined;
        priorityColor = const Color(0xFFFF3B30);
        break;
      case 'high':
        iconData = Icons.warning_amber_outlined;
        priorityColor = Colors.amberAccent.shade400;
        break;
      case 'medium':
        iconData = Icons.info_outline;
        priorityColor = const Color(0xFF0066FF);
        break;
      case 'low':
      default:
        iconData = Icons.notifications_none_outlined;
        priorityColor = Colors.white54;
        break;
    }

    final formattedTime = DateFormat('hh:mm a').format(n.createdAt);

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30), size: 24),
      ),
      onDismissed: (_) async {
        final db = ref.read(databaseProvider);
        await db.notificationDao.deleteNotification(n.id);
      },
      child: GestureDetector(
        onTap: () => _handleNotificationTap(context, ref, n),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.isRead ? Colors.white.withOpacity(0.015) : priorityColor.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: n.isRead
                  ? Colors.white.withOpacity(0.04)
                  : priorityColor.withOpacity(0.25),
              width: n.isRead ? 1.0 : 1.3,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority indicator icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: priorityColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedTime,
                          style: const TextStyle(color: Colors.white30, fontSize: 10.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.body,
                      style: TextStyle(
                        color: n.isRead ? Colors.white54 : Colors.white70,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref, AppNotification n) async {
    // 1. Mark as read
    if (!n.isRead) {
      final db = ref.read(databaseProvider);
      await db.notificationDao.markAsRead(n.id);
    }

    // 2. Open Related Screen based on title/body keyword matches
    final title = n.title.toLowerCase();
    final body = n.body.toLowerCase();

    if (title.contains('sms') || body.contains('sms') || title.contains('draft') || body.contains('draft')) {
      context.push('/sms-drafts');
    } else if (title.contains('goal') || body.contains('goal')) {
      context.push('/goals');
    } else if (title.contains('budget') || body.contains('budget')) {
      context.push('/budgets');
    } else if (title.contains('bill') || body.contains('bill') || title.contains('subscription') || body.contains('subscription')) {
      context.push('/bills');
    } else if (title.contains('advisor') || body.contains('advisor') || title.contains('recommendation') || body.contains('recommendation')) {
      context.push('/advisor');
    } else {
      // Show details dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0F1A1C),
          title: Text(n.title, style: const TextStyle(color: Colors.white)),
          content: Text(n.body, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF00E5FF))),
            ),
          ],
        ),
      );
    }
  }

  void _confirmDeleteAll(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A1C),
        title: const Text('Clear All Notifications?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to permanently delete all notifications?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.notificationDao.deleteAllNotifications(userId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications deleted.'),
                    backgroundColor: Color(0xFF0F1A1C),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
