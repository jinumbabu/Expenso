import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../sms_parser/presentation/providers/sms_parser_provider.dart';
import '../../../advisor/presentation/providers/advisor_provider.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/ecg_pulse_ring.dart';
import '../../../../shared/widgets/blue_donut_chart.dart';
import '../../../../core/services/notification_service.dart';
import '../../../budgets/presentation/screens/budgets_screen.dart';

final dashboardSubscriptionsProvider = StreamProvider.autoDispose<List<Subscription>>((ref) {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return const Stream.empty();
  return db.subscriptionDao.watchSubscriptionsForUser(userId);
});

class DashboardSummaryScreen extends ConsumerWidget {
  const DashboardSummaryScreen({super.key});

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final txsAsync = ref.watch(expenseListNotifierProvider);
    final advisor = ref.watch(advisorProvider);

    // Calculate dynamic values
    int totalIncome = 0;
    int totalExpense = 0;

    txsAsync.maybeWhen(
      data: (txs) {
        for (var tx in txs) {
          if (tx.type == 'income') {
            totalIncome += tx.amount;
          } else if (tx.type == 'expense') {
            totalExpense += tx.amount;
          }
        }
      },
      orElse: () {},
    );

    final finalIncome = totalIncome;
    final finalExpense = totalExpense;
    final finalSavings = finalIncome - finalExpense;

    // Calculate dynamic budget left from budgets database
    final budgetsAsync = ref.watch(budgetStatusProviderList);
    int dynamicBudgetLeft = 0; 
    budgetsAsync.maybeWhen(
      data: (statuses) {
        final overall = statuses.where((s) => s.budget.categoryId == null).toList();
        if (overall.isNotEmpty) {
          dynamicBudgetLeft = overall.first.remainingAmount;
        } else if (statuses.isNotEmpty) {
          dynamicBudgetLeft = statuses.fold(0, (sum, s) => sum + s.remainingAmount);
        } else {
          dynamicBudgetLeft = 0; 
        }
      },
      orElse: () {},
    );
    final finalBudgetLeft = dynamicBudgetLeft;

    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final unreadCount = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    final double savingsPercentage = finalIncome > 0 ? (finalSavings / finalIncome) : 0.66;
    final double expensesPercentage = 1.0 - savingsPercentage;

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
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(expenseListNotifierProvider.notifier).loadTransactions();
              await ref.read(advisorProvider.notifier).calculateFinancialOverview();
            },
            color: const Color(0xFF0066FF),
            backgroundColor: const Color(0xFF0A0A0A),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              children: [
                // 1. Redesigned Header
                _buildHeader(context, ref, auth, advisor, unreadCount),
                const SizedBox(height: 24),

                // Pending SMS drafts banner
                ref.watch(transactionDraftsStreamProvider).maybeWhen(
                  data: (drafts) {
                    if (drafts.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0066FF).withOpacity(0.15),
                            const Color(0xFF0066FF).withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.textsms_outlined, color: Color(0xFF00E5FF), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You have ${drafts.length} pending SMS transaction draft${drafts.length > 1 ? "s" : ""}.',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/sms-drafts'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF00E5FF),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),

                // 2. Net Worth Card
                _buildNetWorthCard(
                  context,
                  finalSavings,
                  finalIncome,
                  finalExpense,
                  finalBudgetLeft,
                  savingsPercentage,
                  expensesPercentage,
                ),
                const SizedBox(height: 20),

                // 3. AI Quick Add
                const _AiQuickAddWidget(),
                const SizedBox(height: 24),

                // 4. AI Financial Assistant Section
                _buildAiAssistantSection(context, advisor),
                const SizedBox(height: 24),

                // 5. Feature Grid
                _buildFeatureGrid(context),
                const SizedBox(height: 28),

                // 6. Upcoming Bills
                _buildUpcomingBillsSection(context),
                const SizedBox(height: 120), // Padding for floating nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header Builder
  Widget _buildHeader(BuildContext context, WidgetRef ref, AuthState auth, AdvisorState advisor, int unreadCount) {
    final todayDay = DateTime.now().day;
    final userName = auth.user?.displayName ?? 'Jinu';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Actions: Notifications, Calendar, Health, Profile
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Notifications with badge
            _buildHeaderIconButton(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 20),
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(color: Color(0xFF0066FF), shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () => _showNotificationsSheet(context, ref),
            ),
            const SizedBox(width: 8),
            // Calendar showing today's date
            _buildHeaderIconButton(
              child: Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Column(
                  children: [
                    Container(height: 3, color: const Color(0xFF0066FF)),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$todayDay',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () => context.push('/calendar'),
            ),
            const SizedBox(width: 8),
            // Health Score Ring (ECG Wave)
            GestureDetector(
              onTap: () => context.push('/advisor'),
              child: EcgPulseRing(
                healthScore: advisor.healthScore,
                size: 34,
                ringColor: const Color(0xFF0066FF),
              ),
            ),
            const SizedBox(width: 8),
            // Profile Avatar with blue glow border
            GestureDetector(
              onTap: () => _showProfileDialog(context, auth),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.8), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withOpacity(0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF001F4D),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'J',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Center(child: child),
      ),
    );
  }

  // Net Worth Card Builder
  Widget _buildNetWorthCard(
    BuildContext context,
    int savings,
    int income,
    int expenses,
    int budgetLeft,
    double savingsPct,
    double expensesPct,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'NET WORTH',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.visibility_outlined, color: Colors.white.withOpacity(0.3), size: 16),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatMoney(savings),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Blue Donut Chart + Percentages
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BlueDonutChart(savingsPercentage: savingsPct, size: 54),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(expensesPct * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white60, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      const Text('Expenses', style: TextStyle(color: Colors.white30, fontSize: 8.5)),
                      const SizedBox(height: 3),
                      Text(
                        '${(savingsPct * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      const Text('Savings', style: TextStyle(color: Colors.white30, fontSize: 8.5)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 4 Micro Grid Cards
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  icon: Icons.arrow_downward_rounded,
                  title: 'Income',
                  value: _formatMoney(income),
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniCard(
                  icon: Icons.arrow_upward_rounded,
                  title: 'Expenses',
                  value: _formatMoney(expenses),
                  isPositive: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Savings',
                  value: _formatMoney(savings),
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniCard(
                  icon: Icons.pie_chart_outline_outlined,
                  title: 'Budget Left',
                  value: _formatMoney(budgetLeft),
                  isPositive: true,
                  isSpecialAccent: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isPositive,
    bool isSpecialAccent = false,
  }) {
    Color valueColor = Colors.white;
    Color iconColor = Colors.white54;
    Color cardBg = Colors.white.withOpacity(0.02);
    Color borderColor = Colors.white.withOpacity(0.04);

    if (isSpecialAccent) {
      valueColor = const Color(0xFFB5179E);
      iconColor = const Color(0xFFB5179E);
    } else if (isPositive) {
      valueColor = const Color(0xFF00E5FF);
      iconColor = const Color(0xFF0066FF);
      cardBg = const Color(0xFF0066FF).withOpacity(0.04);
      borderColor = const Color(0xFF0066FF).withOpacity(0.08);
    } else {
      valueColor = const Color(0xFFFF3B30);
      iconColor = const Color(0xFFFF3B30);
      cardBg = const Color(0xFFFF3B30).withOpacity(0.04);
      borderColor = const Color(0xFFFF3B30).withOpacity(0.08);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 12),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(color: valueColor, fontSize: 11.5, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // AI Assistant Insights section
  Widget _buildAiAssistantSection(BuildContext context, AdvisorState advisor) {
    final List<Map<String, dynamic>> items = [];

    // Add spending alerts (high priority warnings)
    for (var alert in advisor.spendingAlerts) {
      items.add({
        'icon': Icons.warning_amber_rounded,
        'title': alert,
        'subtitle': 'Spending Warning Alert',
      });
    }

    // Add AI insights
    for (var insight in advisor.aiInsights) {
      if (insight.contains('!')) {
        final idx = insight.indexOf('!');
        items.add({
          'icon': Icons.auto_awesome,
          'title': insight.substring(0, idx + 1),
          'subtitle': insight.substring(idx + 1).trim(),
        });
      } else if (insight.contains('.')) {
        final idx = insight.indexOf('.');
        items.add({
          'icon': Icons.lightbulb_outline_rounded,
          'title': insight.substring(0, idx + 1),
          'subtitle': insight.substring(idx + 1).trim(),
        });
      } else {
        items.add({
          'icon': Icons.lightbulb_outline_rounded,
          'title': insight,
          'subtitle': 'Advisor Insight',
        });
      }
    }

    // Fallback if list is empty
    if (items.isEmpty) {
      items.add({
        'icon': Icons.info_outline_rounded,
        'title': 'No insights generated yet',
        'subtitle': 'Log more transactions to see personalized AI insights here.',
      });
    }

    final displayItems = items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome_outlined, color: Color(0xFF0066FF), size: 18),
            SizedBox(width: 8),
            Text(
              'AI FINANCIAL ASSISTANT',
              style: TextStyle(
                color: Color(0xFF0066FF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Glass layout list
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              ...displayItems.map((item) {
                final isLast = item == displayItems.last;
                return Column(
                  children: [
                    _buildInsightTile(
                      icon: item['icon'] as IconData,
                      title: item['title'] as String,
                      subtitle: (item['subtitle'] as String).isEmpty ? 'Advisor Insight' : item['subtitle'] as String,
                      onTap: () => context.push('/advisor'),
                    ),
                    if (!isLast) const Divider(color: Colors.white10, height: 1),
                  ],
                );
              }),
              const SizedBox(height: 8),
              // View All Button
              GestureDetector(
                onTap: () => context.push('/advisor'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View All Insights',
                        style: TextStyle(
                          color: const Color(0xFF00E5FF).withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, color: const Color(0xFF00E5FF).withOpacity(0.9), size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0066FF).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF0066FF), size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white30, fontSize: 11),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
      onTap: onTap,
    );
  }

  // Feature Grid Builder
  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.12,
      children: [
        _buildGridCard(
          context,
          icon: Icons.account_balance_wallet_outlined,
          label: 'Expenses',
          subtitle: 'View & Manage',
          color: const Color(0xFF0066FF),
          onTap: () => StatefulNavigationShell.of(context).goBranch(1),
        ),
        _buildGridCard(
          context,
          icon: Icons.account_balance_outlined,
          label: 'Account',
          subtitle: 'All Accounts',
          color: const Color(0xFF00E5FF),
          onTap: () => context.push('/privacy-settings'),
        ),
        _buildGridCard(
          context,
          icon: Icons.pie_chart_outline_outlined,
          label: 'Budget',
          subtitle: 'Plan & Track',
          color: const Color(0xFF7209B7),
          onTap: () => context.push('/budgets'),
        ),
        _buildGridCard(
          context,
          icon: Icons.track_changes_outlined,
          label: 'Goals',
          subtitle: 'Set & Achieve',
          color: const Color(0xFFF72585),
          onTap: () => context.push('/goals'),
        ),
        _buildGridCard(
          context,
          icon: Icons.bar_chart_outlined,
          label: 'Reports',
          subtitle: 'Analytics & Trends',
          color: const Color(0xFF4CC9F0),
          onTap: () => context.push('/analytics'),
        ),
        _buildGridCard(
          context,
          icon: Icons.calendar_month_outlined,
          label: 'Calendar',
          subtitle: 'Spending Heatmap',
          color: const Color(0xFF4895EF),
          onTap: () => context.push('/calendar'),
        ),
      ],
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white30, fontSize: 8.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Upcoming Bills section
  Widget _buildUpcomingBillsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'UPCOMING BILLS',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View All', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: Consumer(
            builder: (context, ref, child) {
              final subsAsync = ref.watch(dashboardSubscriptionsProvider);
              return subsAsync.when(
                data: (subs) {
                  if (subs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.01),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.03)),
                      ),
                      child: const Text(
                        'All caught up! No upcoming bills or subscriptions.',
                        style: TextStyle(color: Colors.white30, fontSize: 12),
                      ),
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: subs.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final sub = subs[index];
                      final firstChar = sub.title.isNotEmpty ? sub.title[0].toUpperCase() : 'B';
                      final daysLeft = sub.renewalDate.difference(DateTime.now()).inDays;
                      final dueText = daysLeft == 0 
                          ? 'Due Today' 
                          : (daysLeft < 0 ? 'Overdue' : 'Due in $daysLeft Days');
                      final isDueToday = daysLeft <= 0;
                      
                      return _buildBillCard(
                        logo: firstChar,
                        logoColor: const Color(0xFF0066FF),
                        title: sub.title,
                        dueText: dueText,
                        amount: _formatMoney(sub.monthlyCost),
                        isDueToday: isDueToday,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, s) => const SizedBox.shrink(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBillCard({
    required String logo,
    required Color logoColor,
    required String title,
    required String dueText,
    required String amount,
    required bool isDueToday,
  }) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: logoColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                logo,
                style: TextStyle(color: logoColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dueText,
                  style: TextStyle(
                    color: isDueToday ? const Color(0xFFFF3B30) : const Color(0xFF0066FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Profile Dialog Builder
  void _showProfileDialog(BuildContext context, AuthState auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF0066FF), width: 1.2),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0066FF),
              child: Text(
                (auth.user?.displayName ?? 'J').substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    auth.user?.displayName ?? 'Jinu',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    auth.user?.email ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(color: Colors.white10, height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF0066FF)),
              title: const Text('Sync & Backup', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text('Encrypt and save database', style: TextStyle(color: Colors.white38, fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                context.push('/backup');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shield_outlined, color: Color(0xFFB5179E)),
              title: const Text('Privacy & Security', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text('AI privacy mode & memory logs', style: TextStyle(color: Colors.white38, fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                context.push('/privacy-settings');
              },
            ),
            // Access Consumer inside builder using Consumer widget
            Consumer(
              builder: (context, ref, child) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: Color(0xFFFF3B30)),
                  title: const Text('Logout Session', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Sign out of your account', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(authProvider.notifier).logout();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050505),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final notificationsAsync = ref.watch(notificationsStreamProvider);
            final auth = ref.read(authProvider);
            final userId = auth.user?.id;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (userId != null)
                            TextButton(
                              onPressed: () async {
                                final db = ref.read(databaseProvider);
                                await db.notificationDao.markAllAsRead(userId);
                              },
                              child: const Text('Mark all as read', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13)),
                            ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      Expanded(
                        child: notificationsAsync.when(
                          data: (list) {
                            if (list.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.notifications_off_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
                                    const SizedBox(height: 12),
                                    const Text('No notifications yet', style: TextStyle(color: Colors.white30, fontSize: 13)),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              controller: scrollController,
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final n = list[index];
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

                                return Dismissible(
                                  key: Key(n.id),
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: const Color(0xFFFF3B30).withOpacity(0.2),
                                    child: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
                                  ),
                                  onDismissed: (_) async {
                                    final db = ref.read(databaseProvider);
                                    await db.notificationDao.deleteNotification(n.id);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: n.isRead ? Colors.white.withOpacity(0.01) : priorityColor.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: n.isRead
                                            ? Colors.white.withOpacity(0.03)
                                            : priorityColor.withOpacity(0.2),
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () async {
                                        if (!n.isRead) {
                                          final db = ref.read(databaseProvider);
                                          await db.notificationDao.markAsRead(n.id);
                                        }
                                      },
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: priorityColor.withOpacity(0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(iconData, color: priorityColor, size: 18),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  n.title,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  n.body,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  DateFormat('dd MMM hh:mm a').format(n.createdAt),
                                                  style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// AI Quick Add Entry Widget
class _AiQuickAddWidget extends ConsumerStatefulWidget {
  const _AiQuickAddWidget();

  @override
  ConsumerState<_AiQuickAddWidget> createState() => _AiQuickAddWidgetState();
}

class _AiQuickAddWidgetState extends ConsumerState<_AiQuickAddWidget> {
  final _controller = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isProcessing = true);

    try {
      final nlpService = ref.read(nlpServiceProvider);
      final result = await nlpService.parseExpense(text);
      if (result != null && mounted) {
        _controller.clear();
        _showConfirmationSheet(context, result);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to parse text. Try: "Spent 250 on tea"'),
              backgroundColor: Color(0xFFFF3B30),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFFF3B30)),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _startVoiceAdd() async {
    final transcribedText = await showGeneralDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _VoiceListeningOverlay();
      },
    );

    if (transcribedText != null && transcribedText.trim().isNotEmpty) {
      var textToProcess = transcribedText;
      if (textToProcess.startsWith('Simulated: ')) {
        textToProcess = textToProcess.replaceFirst('Simulated: ', '');
      }

      setState(() => _isProcessing = true);
      try {
        final nlpService = ref.read(nlpServiceProvider);
        final result = await nlpService.parseExpense(textToProcess);
        if (result != null && mounted) {
          _showConfirmationSheet(context, result);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to parse voice transcription.'),
                backgroundColor: Color(0xFFFF3B30),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFFF3B30)),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _startOcrAdd() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF050505),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Scan Receipt',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFF0066FF)),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: Color(0xFF0066FF)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final ocrService = ref.read(ocrServiceProvider);
    final pickedFile = await ocrService.pickImage(source);
    if (pickedFile == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF050505),
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF0066FF)),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Scanning receipt with Gemini AI...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final ocrResult = await ocrService.scanReceipt(File(pickedFile.path));
      if (mounted) Navigator.pop(context); // pop loading dialog

      if (ocrResult != null && mounted) {
        final result = NlpParsedResult(
          amount: ocrResult.amount,
          category: ocrResult.category,
          merchant: ocrResult.merchant,
          type: 'expense',
          date: ocrResult.date,
          confidence: ocrResult.confidence,
        );
        _showConfirmationSheet(context, result);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to scan receipt. Please input manually.'),
              backgroundColor: Color(0xFFFF3B30),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // pop loader in case it didn't pop
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanning failed: $e'), backgroundColor: const Color(0xFFFF3B30)),
        );
      }
    }
  }

  void _showConfirmationSheet(BuildContext context, NlpParsedResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050505),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _AiConfirmSheet(result: result),
    );
  }

  void _showTypeInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF0066FF), width: 1.2),
        ),
        title: const Text('Type Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Spent 350 on coffee',
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _submitText();
            },
            child: const Text('Process', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF0066FF).withOpacity(0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withOpacity(0.03),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, color: Color(0xFF00E5FF), size: 16),
              const SizedBox(width: 8),
              const Text(
                'AI QUICK ADD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF0066FF).withOpacity(0.2),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'BETA',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Instantly add transactions using voice, camera, or text.',
            style: TextStyle(color: Colors.white30, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickAddButton(
                  icon: Icons.mic_none_outlined,
                  label: 'Voice Input',
                  onTap: _isProcessing ? null : _startVoiceAdd,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAddButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Scan Receipt',
                  onTap: _isProcessing ? null : _startOcrAdd,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAddButton(
                  icon: Icons.edit_outlined,
                  label: 'Type Text',
                  onTap: _showTypeInputDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing && label == 'Voice Input')
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(color: Color(0xFF00E5FF), strokeWidth: 1.5),
              )
            else
              Icon(icon, color: const Color(0xFF00E5FF), size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AI Confirmation Dialog Bottom Sheet
class _AiConfirmSheet extends ConsumerStatefulWidget {
  final NlpParsedResult result;

  const _AiConfirmSheet({required this.result});

  @override
  ConsumerState<_AiConfirmSheet> createState() => _AiConfirmSheetState();
}

class _AiConfirmSheetState extends ConsumerState<_AiConfirmSheet> {
  late String _type;
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late TextEditingController _descriptionController;
  String? _selectedCategoryId;
  String? _selectedPaymentMethodId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.result.type;
    _amountController = TextEditingController(text: widget.result.amount.toStringAsFixed(2));
    _merchantController = TextEditingController(text: widget.result.merchant ?? '');
    _descriptionController = TextEditingController(
      text: widget.result.merchant != null ? 'Bought ${widget.result.merchant}' : 'AI transaction entry',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) throw Exception("User not authenticated");

      final doubleAmount = double.parse(_amountController.text);
      final intAmount = (doubleAmount * 100).round();

      final transaction = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        categoryId: _selectedCategoryId,
        paymentMethodId: _selectedPaymentMethodId,
        type: _type,
        amount: intAmount,
        currency: auth.user?.currency ?? 'INR',
        merchant: _merchantController.text.trim().isNotEmpty ? _merchantController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        date: DateTime.now(),
        source: 'ai_nlp',
        isRecurring: false,
        confidenceScore: widget.result.confidence,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(expenseListNotifierProvider.notifier).addTransaction(transaction);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00E5FF)),
                SizedBox(width: 8),
                Text('AI transaction saved!'),
              ],
            ),
            backgroundColor: Color(0xFF0066FF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: const Color(0xFFFF3B30)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    final categories = categoriesAsync.maybeWhen(data: (c) => c, orElse: () => <Category>[]);
    final paymentMethods = paymentMethodsAsync.maybeWhen(data: (p) => p, orElse: () => <PaymentMethod>[]);

    if (_selectedCategoryId == null && categories.isNotEmpty) {
      final match = categories.firstWhere(
        (c) => c.name.toLowerCase() == widget.result.category.toLowerCase(),
        orElse: () => categories.first,
      );
      _selectedCategoryId = match.id;
    }

    if (_selectedPaymentMethodId == null && paymentMethods.isNotEmpty) {
      _selectedPaymentMethodId = paymentMethods.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AI Extracted Details',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Expense')),
                  selected: _type == 'expense',
                  onSelected: (val) => setState(() => _type = 'expense'),
                  selectedColor: const Color(0xFFFF3B30).withOpacity(0.25),
                  backgroundColor: Colors.white.withOpacity(0.04),
                  labelStyle: TextStyle(color: _type == 'expense' ? const Color(0xFFFF3B30) : Colors.white60),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Income')),
                  selected: _type == 'income',
                  onSelected: (val) => setState(() => _type = 'income'),
                  selectedColor: const Color(0xFF0066FF).withOpacity(0.25),
                  backgroundColor: Colors.white.withOpacity(0.04),
                  labelStyle: TextStyle(color: _type == 'income' ? const Color(0xFF00E5FF) : Colors.white60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('AMOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.payments, color: Color(0xFF00E5FF)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          const Text('MERCHANT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _merchantController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.storefront, color: Color(0xFF00E5FF)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          const Text('CATEGORY', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            dropdownColor: const Color(0xFF050505),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.folder, color: Color(0xFF00E5FF)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            items: categories.map((c) {
              return DropdownMenuItem<String>(
                value: c.id,
                child: Text(c.name),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategoryId = val),
          ),
          const SizedBox(height: 16),

          const Text('PAYMENT METHOD', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethodId,
            dropdownColor: const Color(0xFF050505),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF00E5FF)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            items: paymentMethods.map((pm) {
              return DropdownMenuItem<String>(
                value: pm.id,
                child: Text(pm.name),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedPaymentMethodId = val),
          ),
          const SizedBox(height: 16),

          const Text('NOTE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.note, color: Color(0xFF00E5FF)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('CONFIRM & SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _VoiceListeningOverlay extends ConsumerStatefulWidget {
  const _VoiceListeningOverlay();

  @override
  ConsumerState<_VoiceListeningOverlay> createState() => _VoiceListeningOverlayState();
}

class _VoiceListeningOverlayState extends ConsumerState<_VoiceListeningOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSpeech();
    });
  }

  void _startSpeech() {
    ref.read(voiceServiceProvider.notifier).startListening(
      onResult: (text) {
        setState(() {
          _currentText = text;
        });
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceServiceProvider);
    final hasError = voiceState.error != null;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: BackdropFilter(
        filter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.srcOver),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                      onPressed: () {
                        ref.read(voiceServiceProvider.notifier).cancelListening();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final scale = 1.0 + (_animationController.value * 0.15);
                        return Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0066FF).withOpacity(0.15),
                            border: Border.all(
                              color: const Color(0xFF00E5FF).withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0066FF).withOpacity(0.3),
                                blurRadius: 20 * scale,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Transform.scale(
                            scale: scale,
                            child: Icon(
                              hasError ? Icons.mic_off : Icons.mic,
                              color: const Color(0xFF00E5FF),
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    if (voiceState.isListening)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final phase = (index * 0.2);
                              double val = (_animationController.value + phase) % 1.0;
                              if (val > 0.5) val = 1.0 - val;
                              final height = 15 + (val * 40);
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 6,
                                height: height,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF),
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0066FF), Color(0xFF00E5FF)],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      )
                    else
                      Text(
                        hasError ? 'Not Available' : 'Initializing...',
                        style: const TextStyle(color: Colors.white38, fontSize: 14),
                      ),

                    const SizedBox(height: 32),

                    Text(
                      _currentText.isNotEmpty
                          ? '"$_currentText"'
                          : (hasError
                              ? 'Speech recognition not supported on this platform.\nYou can try simulated speech entry instead.'
                              : 'Listening... Say something like:\n"Spent 450 rupees on dinner yesterday"'),
                      style: TextStyle(
                        color: _currentText.isNotEmpty ? Colors.white : Colors.white60,
                        fontSize: _currentText.isNotEmpty ? 20 : 16,
                        fontWeight: _currentText.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                        fontStyle: _currentText.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (voiceState.isListening)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.stop),
                        label: const Text('STOP & PROCESS', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          await ref.read(voiceServiceProvider.notifier).stopListening();
                          if (context.mounted) {
                            Navigator.pop(context, _currentText);
                          }
                        },
                      )
                    else ...[
                      if (hasError) ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () {
                            Navigator.pop(context, 'Simulated: Spent 450 rupees on dinner yesterday at Pizza Hut');
                          },
                          child: const Text('SIMULATE SPEECH INPUT', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.white54),
                        onPressed: () {
                          ref.read(voiceServiceProvider.notifier).cancelListening();
                          Navigator.pop(context);
                        },
                        child: const Text('CANCEL'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
