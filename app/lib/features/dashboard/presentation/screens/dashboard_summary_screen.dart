import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/account_formatters.dart';
import '../../../backup/presentation/providers/backup_provider.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../goals/presentation/providers/goals_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../sms_parser/presentation/providers/sms_parser_provider.dart';
import '../../../advisor/presentation/providers/advisor_provider.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/ecg_pulse_ring.dart';
import '../../../../shared/widgets/reusable_net_worth_ring.dart';
import '../../../../core/services/notification_service.dart';
import '../../../budgets/presentation/screens/budgets_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../../../../shared/widgets/privacy_text.dart';
import '../providers/privacy_provider.dart';
import '../../../../core/services/balance_engine.dart';

final databaseSubscriptionsStreamProvider = StreamProvider.autoDispose<List<Subscription>>((ref) {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return const Stream.empty();
  return db.subscriptionDao.watchSubscriptionsForUser(userId);
});

final databasePendingBillsStreamProvider = StreamProvider.autoDispose<List<Bill>>((ref) {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return const Stream.empty();
  return (db.select(db.bills)
    ..where((t) => t.userId.equals(userId) & t.status.equals('pending'))
  ).watch();
});

final dashboardSubscriptionsProvider = Provider.autoDispose<AsyncValue<List<Subscription>>>((ref) {
  final subsAsync = ref.watch(databaseSubscriptionsStreamProvider);
  final billsAsync = ref.watch(databasePendingBillsStreamProvider);

  if (subsAsync.hasError) return AsyncValue.error(subsAsync.error!, subsAsync.stackTrace!);
  if (billsAsync.hasError) return AsyncValue.error(billsAsync.error!, billsAsync.stackTrace!);

  if (!subsAsync.hasValue || !billsAsync.hasValue) {
    return const AsyncValue.loading();
  }

  final subsList = subsAsync.value!;
  final billsList = billsAsync.value!;

  final List<Subscription> combined = List.from(subsList);
  for (var bill in billsList) {
    combined.add(
      Subscription(
        id: bill.id,
        userId: bill.userId,
        title: bill.title,
        monthlyCost: bill.amount,
        annualCost: bill.amount * 12,
        billingCycle: 'monthly',
        renewalDate: bill.dueDate ?? bill.createdAt,
        providerName: 'SMS Auto-Import',
        confidence: 1.0,
        status: 'active',
        createdAt: bill.createdAt,
        updatedAt: bill.updatedAt,
      ),
    );
  }
  return AsyncValue.data(combined);
});

final hasCheckedBackupRestoreProvider = StateProvider<bool>((ref) => false);
final dismissedOpeningBalancePromptsProvider = StateProvider<Set<String>>((ref) => {});

// Dashboard selected month provider
final dashboardMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Dashboard financial calculation provider
final dashboardFinancialDataProvider = Provider.autoDispose<FinancialData>((ref) {
  final month = ref.watch(dashboardMonthProvider);
  final txsAsync = ref.watch(expenseListNotifierProvider);
  final txs = txsAsync.maybeWhen(
    data: (list) => list,
    orElse: () => <Transaction>[],
  );
  return FinancialCalculationService.calculate(
    transactions: txs,
    selectedMonth: month,
  );
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
    final advisor = ref.watch(advisorProvider);

    final accountsVal = ref.watch(recalculatedAccountsProvider).value ?? [];
    final unpromptedAccounts = accountsVal.where((a) =>
      a.openingBalance == null && 
      (a.type == 'savings' || a.type == 'credit_card')
    ).toList();
    final dismissedPrompts = ref.watch(dismissedOpeningBalancePromptsProvider);
    final accountsToPrompt = unpromptedAccounts.where((a) => !dismissedPrompts.contains(a.id)).toList();

    final hasCheckedRestore = ref.watch(hasCheckedBackupRestoreProvider);
    if (!hasCheckedRestore && auth.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        ref.read(hasCheckedBackupRestoreProvider.notifier).state = true;

        try {
          final backupNotifier = ref.read(backupNotifierProvider.notifier);
          await backupNotifier.loadBackupInfo();
          await backupNotifier.checkAndRunScheduledBackup();
          final backupState = ref.read(backupNotifierProvider);
          
          if (backupState.backups.isNotEmpty && context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF0F1A1C),
                title: const Text('Restore Previous Backup?', style: TextStyle(color: Colors.white)),
                content: const Text(
                  'We found an existing Expenso cloud backup on your Google Drive. Would you like to restore it now?',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Skip', style: TextStyle(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                          ),
                        );
                        
                        await ref.read(backupNotifierProvider.notifier).restoreBackup();
                        
                        await ref.read(expenseListNotifierProvider.notifier).loadTransactions();
                        await ref.read(budgetListNotifierProvider.notifier).loadBudgets();
                        await ref.read(goalsListNotifierProvider.notifier).loadGoals();
                        await ref.read(advisorProvider.notifier).calculateFinancialOverview();
                        
                        if (context.mounted) {
                          Navigator.pop(context); // Dismiss loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Backup restored successfully! All dashboards refreshed.'),
                              backgroundColor: Color(0xFF0066FF),
                            ),
                          );
                        }
                      } catch (err) {
                        if (context.mounted) {
                          Navigator.pop(context); // Dismiss loading
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF0F1A1C),
                              title: const Text('Restore Failed', style: TextStyle(color: Colors.white)),
                              content: Text(
                                err.toString().replaceAll('Exception:', '').trim(),
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK', style: TextStyle(color: Color(0xFF00E5FF))),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Restore', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        } catch (e) {
          debugPrint('DashboardSummaryScreen: Error checking backup restore: $e');
        }
      });
    }

    final selectedMonth = ref.watch(dashboardMonthProvider);
    final financialData = ref.watch(dashboardFinancialDataProvider);

    final finalIncome = financialData.monthlyIncome;
    final finalExpense = financialData.monthlyExpenses;
    final finalOpeningBalance = financialData.openingBalance;
    final accountSummaryAsync = ref.watch(accountSummaryProvider);
    final finalNetWorth = accountSummaryAsync.maybeWhen(
      data: (summary) => summary.netAssets,
      orElse: () => 0,
    );
    final isPrivate = ref.watch(privacyModeProvider);

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
    final draftsAsync = ref.watch(transactionDraftsStreamProvider);
    final unreadNotifsCount = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => !n.isRead).length,
      orElse: () => 0,
    );
    final draftsCount = draftsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );
    final unreadCount = unreadNotifsCount + (draftsCount > 0 ? 1 : 0);


    final finalCcOutstanding = accountSummaryAsync.maybeWhen(
      data: (summary) => summary.ccOutstanding,
      orElse: () => 0,
    );

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

                // Opening Balance Suggestion Banner
                if (accountsToPrompt.isNotEmpty) ...[
                  _buildOpeningBalanceSuggestionBanner(context, ref, accountsToPrompt.first),
                  const SizedBox(height: 16),
                ],

                // SMS Permission warning banner
                () {
                  final scannerState = ref.watch(smsScannerProvider);
                  if (scannerState.smsPermissionStatus.isGranted) {
                    return const SizedBox.shrink();
                  }

                  final isPermanentlyDenied = scannerState.smsPermissionStatus.isPermanentlyDenied;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withOpacity(0.15),
                          Colors.amber.withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SMS Sync is Disabled',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isPermanentlyDenied
                                    ? 'SMS permission is permanently denied. Please enable it in App Settings to track expenses automatically.'
                                    : 'Expenso needs SMS permission to automatically read and categorize bank alerts with zero manual entry.',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (isPermanentlyDenied) {
                              openAppSettings();
                            } else {
                              await ref.read(smsScannerProvider.notifier).requestSmsPermission();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amberAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            isPermanentlyDenied ? 'Settings' : 'Grant',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }(),

                // 2. Month Selector
                _buildMonthSelector(context, ref, selectedMonth),
                const SizedBox(height: 16),

                // 3. Net Worth Card
                _buildNetWorthCard(
                  context,
                  ref,
                  finalNetWorth,
                  finalIncome,
                  finalExpense,
                  finalBudgetLeft,
                  finalOpeningBalance,
                  finalCcOutstanding,
                  isPrivate,
                ),
                const SizedBox(height: 20),

                // 3. AI Quick Add
                const _AiQuickAddWidget(),
                const SizedBox(height: 24),

                // 4. Feature Grid
                _buildFeatureGrid(context),
                const SizedBox(height: 28),

                // 5. Upcoming Bills
                _buildUpcomingBillsSection(context),
                const SizedBox(height: 120), // Padding for floating nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, WidgetRef ref, DateTime selectedMonth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 24),
          onPressed: () {
            final newMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
            ref.read(dashboardMonthProvider.notifier).state = newMonth;
          },
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showDashboardMonthYearPicker(context, ref, selectedMonth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF00E5FF), size: 14),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMMM yyyy').format(selectedMonth).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
          onPressed: () {
            final newMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
            ref.read(dashboardMonthProvider.notifier).state = newMonth;
          },
        ),
      ],
    );
  }

  void _showDashboardMonthYearPicker(BuildContext context, WidgetRef ref, DateTime selectedMonth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF030D1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final months = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white70),
                        onPressed: () {
                          setModalState(() {
                            selectedMonth = DateTime(selectedMonth.year - 1, selectedMonth.month, 1);
                          });
                        },
                      ),
                      Text(
                        '${selectedMonth.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white70),
                        onPressed: () {
                          setModalState(() {
                            selectedMonth = DateTime(selectedMonth.year + 1, selectedMonth.month, 1);
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthName = months[index];
                      final isSelected = selectedMonth.month == index + 1;
                      
                      return GestureDetector(
                        onTap: () {
                          final newMonth = DateTime(selectedMonth.year, index + 1, 1);
                          ref.read(dashboardMonthProvider.notifier).state = newMonth;
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00E5FF).withOpacity(0.2)
                                : Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white.withOpacity(0.05),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              monthName.substring(0, 3).toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
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
              onTap: () => context.push('/notifications'),
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
    WidgetRef ref,
    int netWorth,
    int income,
    int expenses,
    int budgetLeft,
    int openingBalance,
    int ccOutstanding,
    bool isPrivate,
  ) {
    final bool hasData = (openingBalance + income + expenses) > 0;
    final int availableFunds = openingBalance + income;
    double savingsPct = 0.0;
    double expensesPct = 0.0;
    bool isOverspent = false;
    int overspentAmount = 0;

    if (!hasData) {
      expensesPct = 0.0;
      savingsPct = 0.0;
    } else if (availableFunds <= 0) {
      expensesPct = 1.0;
      savingsPct = 0.0;
      if (expenses > 0) {
        isOverspent = true;
        overspentAmount = expenses - availableFunds;
      }
    } else {
      if (expenses >= availableFunds) {
        expensesPct = 1.0;
        savingsPct = 0.0;
        if (expenses > availableFunds) {
          isOverspent = true;
          overspentAmount = expenses - availableFunds;
        }
      } else {
        expensesPct = expenses / availableFunds;
        savingsPct = ((availableFunds - expenses) / availableFunds).clamp(0.0, 1.0);
      }
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left interactive group: Net Worth details
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/net-worth-detail'),
                  behavior: HitTestBehavior.opaque,
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
                          // Reliable Eye Icon for toggling Privacy Mode
                          GestureDetector(
                            onTap: () => ref.read(privacyModeProvider.notifier).toggle(),
                            behavior: HitTestBehavior.opaque,
                            child: Icon(
                              isPrivate ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white.withOpacity(0.35),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: PrivacyText(
                          rawValue: _formatMoney(netWorth),
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
              ),
              const SizedBox(width: 12),
              // Right interactive group: Expenses/Remaining ring and info
              GestureDetector(
                onTap: () => context.push('/expense-breakdown'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasData) ...[
                        ReusableNetWorthRing(
                          key: ValueKey('net_worth_ring_${ref.watch(dashboardMonthProvider).toIso8601String()}'),
                          valueFraction: savingsPct,
                          size: 54,
                          trackColor: const Color(0xFFFF3B30),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (!hasData)
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'No financial',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'data yet',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                isPrivate ? '**%' : '${(expensesPct * 100).toStringAsFixed(0)}%',
                                key: ValueKey('exp_$isPrivate'),
                                style: const TextStyle(
                                  color: Color(0xFFFF3B30),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text('Expenses', style: TextStyle(color: Colors.white30, fontSize: 8.5)),
                            const SizedBox(height: 3),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                isPrivate ? '**%' : '${(savingsPct * 100).toStringAsFixed(0)}%',
                                key: ValueKey('sav_$isPrivate'),
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text('Remaining', style: TextStyle(color: Colors.white30, fontSize: 8.5)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isOverspent) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFFFF3B30).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30), size: 10),
                  const SizedBox(width: 4),
                  Text(
                    'Overspent: ${_formatMoney(overspentAmount)}',
                    style: const TextStyle(
                      color: Color(0xFFFF3B30),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // 4 Micro Grid Cards
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/monthly-transactions/income'),
                  child: _buildMiniCard(
                    icon: Icons.arrow_downward_rounded,
                    title: 'Income',
                    value: _formatMoney(income),
                    isPositive: true,
                    isPrivate: isPrivate,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/monthly-transactions/expense'),
                  child: _buildMiniCard(
                    icon: Icons.arrow_upward_rounded,
                    title: 'Expenses',
                    value: _formatMoney(expenses),
                    isPositive: false,
                    isPrivate: isPrivate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCarryForwardSheet(context, ref, openingBalance),
                  child: _buildMiniCard(
                    icon: Icons.next_plan_outlined,
                    title: 'Carry Forward',
                    value: _formatMoney(openingBalance),
                    isPositive: openingBalance >= 0,
                    isPrivate: isPrivate,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/accounts'),
                  child: _buildMiniCard(
                    icon: Icons.credit_card_rounded,
                    title: 'Credit Card',
                    value: formatCreditCardAmount(_formatMoney(ccOutstanding)),
                    isPositive: false,
                    isPrivate: isPrivate,
                  ),
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
    required bool isPrivate,
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
                PrivacyText(
                  rawValue: value,
                  style: TextStyle(color: valueColor, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCarryForwardSheet(BuildContext context, WidgetRef ref, int openingBalance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050505),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Carry Forward Balance',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                const Text(
                  'WHAT IS CARRY FORWARD?',
                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Carry Forward is the net balance of all your savings accumulated from previous months. It represents your opening balance for the current month.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                const Text(
                  'FORMULA',
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text(
                    'Carry Forward = Total Past Income - Total Past Expenses',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Opening Balance:',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    PrivacyText(
                      rawValue: _formatMoney(openingBalance),
                      style: TextStyle(
                        color: openingBalance >= 0 ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBudgetLeftSheet(BuildContext context, WidgetRef ref, int budgetLeft) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050505),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final budgetStatusAsync = ref.watch(budgetStatusProviderList);

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: budgetStatusAsync.when(
                data: (statuses) {
                  final overallList = statuses.where((s) => s.budget.categoryId == null).toList();
                  final overall = overallList.isNotEmpty ? overallList.first : null;
                  
                  final categoryBudgets = statuses.where((s) => s.budget.categoryId != null).toList();

                  int totalLimit = overall != null ? overall.budget.amount : statuses.fold(0, (sum, s) => sum + s.budget.amount);
                  int totalSpent = overall != null ? overall.spentAmount : statuses.fold(0, (sum, s) => sum + s.spentAmount);
                  int remaining = totalLimit - totalSpent;
                  double utilization = totalLimit == 0 ? 0.0 : totalSpent / totalLimit;

                  final alerts = <String>[];
                  if (utilization >= 1.0) {
                    alerts.add('You have exceeded your total monthly budget limit! ⚠️');
                  } else if (utilization >= 0.8) {
                    alerts.add('Warning: You have utilized ${(utilization * 100).toStringAsFixed(0)}% of your total budget.');
                  }

                  for (var s in categoryBudgets) {
                    final catPct = s.percent;
                    if (catPct >= 1.0) {
                      alerts.add('You have exceeded your "${s.category?.name ?? 'Category'}" budget limit! ⚠️');
                    } else if (catPct >= 0.8) {
                      alerts.add('Warning: Used ${(catPct * 100).toStringAsFixed(0)}% of "${s.category?.name ?? 'Category'}" budget.');
                    }
                  }

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24.0),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Budget Utilization',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),

                      GlassCard(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Monthly Budget', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                PrivacyText(
                                  rawValue: _formatMoney(totalLimit),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Spent', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                PrivacyText(
                                  rawValue: _formatMoney(totalSpent),
                                  style: const TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Remaining Budget', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                PrivacyText(
                                  rawValue: _formatMoney(remaining),
                                  style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: utilization > 1.0 ? 1.0 : utilization,
                                backgroundColor: Colors.white10,
                                color: utilization > 0.8 ? const Color(0xFFFF3B30) : const Color(0xFF0066FF),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Utilization: ${(utilization * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(color: Colors.white30, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (alerts.isNotEmpty) ...[
                        const Text(
                          'BUDGET ALERTS',
                          style: TextStyle(color: Color(0xFFFF3B30), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 10),
                        ...alerts.map((alert) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(alert, style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 11.5))),
                                ],
                              ),
                            )),
                        const SizedBox(height: 24),
                      ],

                      if (categoryBudgets.isNotEmpty) ...[
                        const Text(
                          'CATEGORY-WISE BUDGETS',
                          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categoryBudgets.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final s = categoryBudgets[idx];
                            final progress = s.percent;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.01),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.03)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(s.category?.name ?? 'Category Limit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                      PrivacyText(
                                        rawValue: _formatMoney(s.budget.amount),
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: progress > 1.0 ? 1.0 : progress,
                                      backgroundColor: Colors.white.withOpacity(0.03),
                                      color: progress > 0.8 ? const Color(0xFFFF3B30) : const Color(0xFF0066FF),
                                      minHeight: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Spent: ${_formatMoney(s.spentAmount)}', style: const TextStyle(color: Colors.white30, fontSize: 10)),
                                      Text('Remaining: ${_formatMoney(s.remainingAmount)}', style: TextStyle(color: s.remainingAmount >= 0 ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30), fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                error: (err, _) => Center(child: Text('Error loading budgets: $err')),
              ),
            );
          },
        );
      },
    );
  }



  // Feature Grid Builder
  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        _buildGridCard(
          context,
          icon: Icons.account_balance_wallet_outlined,
          label: 'Expenses',
          subtitle: 'View & Manage',
          color: const Color(0xFF0066FF),
          onTap: () => context.push('/expenses'),
        ),
        _buildGridCard(
          context,
          icon: Icons.account_balance_outlined,
          label: 'Account',
          subtitle: 'All Accounts',
          color: const Color(0xFF00E5FF),
          onTap: () => context.push('/accounts'),
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
          color: const Color(0xFF0A1121).withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
              onPressed: () => context.push('/bills'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View All', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
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
                        color: const Color(0xFF0A1121).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
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
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final sub = subs[index];
                      final firstChar = sub.title.isNotEmpty ? sub.title[0].toUpperCase() : 'B';
                      final daysLeft = sub.renewalDate.difference(DateTime.now()).inDays;
                      final dueText = daysLeft == 0 
                          ? 'Due Today' 
                          : (daysLeft < 0 ? 'Overdue' : 'Due in $daysLeft Days');
                      final isDueToday = daysLeft <= 0;
                      
                      return GestureDetector(
                        onTap: () => context.push('/bills/${sub.id}'),
                        child: _buildBillCard(
                          logo: firstChar,
                          logoColor: const Color(0xFF0066FF),
                          title: sub.title,
                          dueText: dueText,
                          amount: _formatMoney(sub.monthlyCost),
                          isDueToday: isDueToday,
                        ),
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
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1121).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: logoColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                logo,
                style: TextStyle(color: logoColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dueText,
                  style: TextStyle(
                    color: isDueToday ? const Color(0xFFFF3B30) : const Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
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
              leading: const Icon(Icons.auto_awesome_outlined, color: Color(0xFF00E5FF)),
              title: const Text('AI Settings', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text('Configure model & API keys', style: TextStyle(color: Colors.white38, fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                context.push('/ai-settings');
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

  Widget _buildOpeningBalanceSuggestionBanner(BuildContext context, WidgetRef ref, Account acc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withOpacity(0.03),
            blurRadius: 10,
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF00E5FF), size: 20),
              SizedBox(width: 8),
              Text(
                "New account detected!",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "We detected a new bank account \"${acc.displayTitle}\". Would you like to set its opening balance?",
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  ref.read(dismissedOpeningBalancePromptsProvider.notifier).update((state) => {...state, acc.id});
                },
                child: const Text("Later", style: TextStyle(color: Colors.white38)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  _showEnterOpeningBalanceDialog(context, ref, acc);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Set Opening Balance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
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
  bool _isProcessing = false;

  @override
  void dispose() {
    super.dispose();
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

  Future<bool> _checkAndRequestCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        final newStatus = await Permission.camera.request();
        if (newStatus.isGranted) {
          return true;
        }
      }
    } catch (e, stack) {
      debugPrint('Camera permission handling error: $e\n$stack');
    }
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0F1A1C),
          title: const Text('Camera Permission Required', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Expenso needs camera access to scan receipts. Please enable it in Settings.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                try {
                  openAppSettings();
                } catch (e) {
                  debugPrint('Failed to open app settings: $e');
                }
              },
              child: const Text('Open Settings', style: TextStyle(color: Color(0xFF00E5FF))),
            ),
          ],
        ),
      );
    }
    return false;
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

    if (source == ImageSource.camera) {
      final hasPermission = await _checkAndRequestCameraPermission();
      if (!hasPermission) return;
    }

    final ocrService = ref.read(ocrServiceProvider);
    final pickedFile = await ocrService.pickImage(source);
    if (pickedFile == null) return;

    final statusNotifier = ValueNotifier<String>('Preparing Image...');

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        content: Row(
          children: [
            const CircularProgressIndicator(color: Color(0xFF0066FF)),
            const SizedBox(width: 20),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: statusNotifier,
                builder: (context, status, child) {
                  return Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final ocrResult = await ocrService.scanReceipt(
        File(pickedFile.path),
        onStatusChanged: (status) {
          statusNotifier.value = status;
        },
      );
      if (mounted) Navigator.pop(context); // pop loading dialog

      if (ocrResult != null && mounted) {
        final result = NlpParsedResult(
          amount: ocrResult.amount,
          category: ocrResult.category,
          merchant: ocrResult.merchant,
          type: 'expense',
          date: ocrResult.date,
          confidence: ocrResult.confidence,
          merchantAddress: ocrResult.merchantAddress,
          time: ocrResult.time,
          tax: ocrResult.tax,
          currency: ocrResult.currency,
          cardType: ocrResult.cardType,
          last4Digits: ocrResult.last4Digits,
          receiptNumber: ocrResult.receiptNumber,
          invoiceNumber: ocrResult.invoiceNumber,
          discount: ocrResult.discount,
          tips: ocrResult.tips,
          items: ocrResult.items,
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
                  onTap: () => context.push('/quick-add-notepad'),
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
  late TextEditingController _addressController;
  late TextEditingController _taxController;
  late TextEditingController _discountController;
  late TextEditingController _tipsController;
  late TextEditingController _invoiceController;
  late TextEditingController _receiptNumController;
  late TextEditingController _timeController;
  
  String? _selectedCategoryId;
  String? _selectedPaymentMethodId;
  String? _selectedAccountId;
  String? _selectedTransferToAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  List<OcrItem> _items = [];

  @override
  void initState() {
    super.initState();
    _type = widget.result.type;
    _amountController = TextEditingController(text: widget.result.amount.toStringAsFixed(2));
    _merchantController = TextEditingController(text: widget.result.merchant ?? '');
    _descriptionController = TextEditingController(
      text: widget.result.merchant != null ? 'Bought ${widget.result.merchant}' : 'AI transaction entry',
    );
    if (widget.result.notes != null && widget.result.notes!.trim().isNotEmpty) {
      _descriptionController.text = widget.result.notes!;
    }

    _addressController = TextEditingController(text: widget.result.merchantAddress ?? '');
    _taxController = TextEditingController(text: (widget.result.tax ?? 0.0).toStringAsFixed(2));
    _discountController = TextEditingController(text: (widget.result.discount ?? 0.0).toStringAsFixed(2));
    _tipsController = TextEditingController(text: (widget.result.tips ?? 0.0).toStringAsFixed(2));
    _invoiceController = TextEditingController(text: widget.result.invoiceNumber ?? '');
    _receiptNumController = TextEditingController(text: widget.result.receiptNumber ?? '');
    _timeController = TextEditingController(text: widget.result.time ?? '');
    _items = widget.result.items != null ? List<OcrItem>.from(widget.result.items!) : [];

    // Parse date if possible
    if (widget.result.date == 'yesterday') {
      _selectedDate = DateTime.now().subtract(const Duration(days: 1));
    } else if (widget.result.date == 'tomorrow') {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
    } else {
      try {
        final parsed = DateFormat('yyyy-MM-dd').parse(widget.result.date);
        _selectedDate = parsed;
      } catch (_) {
        try {
          final parsed = DateFormat('dd/MM/yyyy').parse(widget.result.date);
          _selectedDate = parsed;
        } catch (_) {}
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // 1. Auto-select category
      final cats = ref.read(categoriesProvider).value ?? [];
      if (cats.isNotEmpty && _selectedCategoryId == null) {
        final matched = cats.firstWhere(
          (c) => c.name.toLowerCase() == widget.result.category.toLowerCase(),
          orElse: () => cats.firstWhere(
            (c) => widget.result.category.toLowerCase().contains(c.name.toLowerCase()) || 
                   c.name.toLowerCase().contains(widget.result.category.toLowerCase()),
            orElse: () => cats.first,
          ),
        );
        setState(() {
          _selectedCategoryId = matched.id;
        });
      }

      // 2. Auto-select payment method
      final pms = ref.read(paymentMethodsProvider).value ?? [];
      if (pms.isNotEmpty && _selectedPaymentMethodId == null) {
        final searchPmName = widget.result.paymentMethodName ?? 'Cash';
        final matched = pms.firstWhere(
          (p) => p.name.toLowerCase() == searchPmName.toLowerCase(),
          orElse: () => pms.firstWhere(
            (p) => searchPmName.toLowerCase().contains(p.name.toLowerCase()) ||
                   p.name.toLowerCase().contains(searchPmName.toLowerCase()),
            orElse: () => pms.first,
          ),
        );
        setState(() {
          _selectedPaymentMethodId = matched.id;
        });
      }

      // 3. Auto-select Account
      final accounts = ref.read(accountsProvider).value ?? [];
      if (accounts.isNotEmpty && _selectedAccountId == null) {
        final explicitName = widget.result.accountName;
        Account? matchedAccount;
        if (explicitName != null && explicitName.isNotEmpty) {
          final matchedList = accounts.where(
            (a) => a.name.toLowerCase().contains(explicitName.toLowerCase()) || 
                   explicitName.toLowerCase().contains(a.name.toLowerCase())
          ).toList();
          if (matchedList.isNotEmpty) matchedAccount = matchedList.first;
        }

        if (matchedAccount == null) {
          final pmName = (widget.result.paymentMethodName ?? '').toLowerCase();
          String targetType = 'savings';
          if (pmName.contains('credit')) {
            targetType = 'credit_card';
          } else if (pmName.contains('cash')) {
            targetType = 'cash';
          } else if (pmName.contains('debit') || pmName.contains('card')) {
            targetType = 'savings';
          } else if (pmName.contains('upi')) {
            targetType = 'savings';
          }

          final typeMatched = accounts.where((a) => a.type.toLowerCase() == targetType).toList();
          if (typeMatched.isNotEmpty) {
            matchedAccount = typeMatched.first;
          } else {
            if (pmName.contains('cash')) {
              matchedAccount = accounts.firstWhere(
                (a) => a.name.toLowerCase().contains('cash'),
                orElse: () => accounts.first,
              );
            } else {
              matchedAccount = accounts.first;
            }
          }
        }

        setState(() {
          _selectedAccountId = matchedAccount?.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    _tipsController.dispose();
    _invoiceController.dispose();
    _receiptNumController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  List<PaymentMethod> _getAvailablePaymentMethodsForType(String type, List<PaymentMethod> allMethods) {
    final t = type.toLowerCase();
    if (t == 'cash') {
      return allMethods.where((pm) => pm.name.toLowerCase() == 'cash').toList();
    } else if (t == 'savings' || t == 'current') {
      return allMethods.where((pm) {
        final name = pm.name.toLowerCase();
        return name == 'upi' || name == 'debit card' || name == 'debit_card' || name == 'net banking' || name == 'net_banking';
      }).toList();
    } else if (t == 'credit_card') {
      return allMethods.where((pm) {
        final name = pm.name.toLowerCase();
        return name == 'credit card' || name == 'credit_card' || name == 'upi' || name == 'net banking' || name == 'net_banking';
      }).toList();
    } else if (t == 'wallet') {
      return allMethods.where((pm) {
        final name = pm.name.toLowerCase();
        return name == 'wallet balance' || name == 'wallet_balance' || name == 'upi';
      }).toList();
    } else if (t == 'loan' || t == 'loan_account') {
      return allMethods.where((pm) {
        final name = pm.name.toLowerCase();
        return name == 'loan disbursement' || name == 'loan_disbursement' || name == 'emi payment' || name == 'emi_payment';
      }).toList();
    } else if (t == 'investment') {
      return allMethods.where((pm) {
        final name = pm.name.toLowerCase();
        return name == 'buy' || name == 'sell' || name == 'transfer';
      }).toList();
    }
    return allMethods;
  }

  Future<void> _save() async {
    if (_type != 'transfer') {
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
    } else {
      if (_selectedAccountId == _selectedTransferToAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source and destination accounts must be different')),
        );
        return;
      }
      if (_selectedTransferToAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select destination account')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) throw Exception("User not authenticated");

      final doubleAmount = double.parse(_amountController.text);
      final intAmount = (doubleAmount * 100).round();
      final now = DateTime.now();

      // Format description with all rich fields
      final noteBuffer = StringBuffer();
      final notesText = _descriptionController.text.trim();
      if (notesText.isNotEmpty) {
        noteBuffer.writeln(notesText);
      }
      
      if (_addressController.text.trim().isNotEmpty) {
        noteBuffer.writeln('📍 Address: ${_addressController.text.trim()}');
      }
      
      final invoice = _invoiceController.text.trim();
      final receipt = _receiptNumController.text.trim();
      if (invoice.isNotEmpty || receipt.isNotEmpty) {
        final List<String> list = [];
        if (invoice.isNotEmpty) list.add('Invoice: $invoice');
        if (receipt.isNotEmpty) list.add('Receipt: $receipt');
        noteBuffer.writeln('📄 ${list.join(" | ")}');
      }

      final doubleTax = double.tryParse(_taxController.text) ?? 0.0;
      final doubleDiscount = double.tryParse(_discountController.text) ?? 0.0;
      final doubleTips = double.tryParse(_tipsController.text) ?? 0.0;
      if (doubleTax > 0 || doubleDiscount > 0 || doubleTips > 0) {
        final List<String> list = [];
        if (doubleTax > 0) list.add('Tax: ₹${doubleTax.toStringAsFixed(2)}');
        if (doubleDiscount > 0) list.add('Discount: ₹${doubleDiscount.toStringAsFixed(2)}');
        if (doubleTips > 0) list.add('Tips: ₹${doubleTips.toStringAsFixed(2)}');
        noteBuffer.writeln('💵 ${list.join(" | ")}');
      }

      if (_items.isNotEmpty) {
        noteBuffer.writeln('🛍️ Items:');
        for (var item in _items) {
          final discountStr = item.discount > 0 ? ' (Disc: ₹${item.discount.toStringAsFixed(0)})' : '';
          noteBuffer.writeln('  - ${item.name} x${item.quantity} @ ₹${item.unitPrice.toStringAsFixed(2)}$discountStr');
        }
      }

      final finalDescription = noteBuffer.toString().trim();

      if (_type == 'transfer') {
        final accounts = ref.read(accountsProvider).value ?? [];
        final sourceAccount = accounts.firstWhere((a) => a.id == _selectedAccountId);
        final destAccount = accounts.firstWhere((a) => a.id == _selectedTransferToAccountId);

        final categoriesList = ref.read(categoriesProvider).value ?? [];
        final transferCat = categoriesList.firstWhere(
          (c) => c.name.toLowerCase().contains('transfer'),
          orElse: () => categoriesList.isNotEmpty ? categoriesList.first : categoriesList.first,
        );
        final String? catId = transferCat.id;

        final sourceId = const Uuid().v4();

        final sourceTx = Transaction(
          id: sourceId,
          userId: userId,
          accountId: _selectedAccountId,
          categoryId: catId,
          type: 'transfer_debit',
          amount: intAmount,
          currency: auth.user?.currency ?? 'INR',
          description: finalDescription.isNotEmpty ? finalDescription : null,
          merchant: 'To ${destAccount.name}',
          date: _selectedDate,
          source: 'ai_nlp',
          isRecurring: false,
          confidenceScore: widget.result.confidence,
          syncStatus: 'pending',
          createdAt: now,
          updatedAt: now,
        );

        final destTx = Transaction(
          id: const Uuid().v4(),
          userId: userId,
          accountId: _selectedTransferToAccountId,
          categoryId: catId,
          type: 'transfer_credit',
          amount: intAmount,
          currency: auth.user?.currency ?? 'INR',
          description: finalDescription.isNotEmpty ? finalDescription : null,
          merchant: 'From ${sourceAccount.name}',
          date: _selectedDate,
          source: 'ai_nlp',
          isRecurring: false,
          syncStatus: 'pending',
          referenceNumber: sourceId,
          confidenceScore: widget.result.confidence,
          createdAt: now,
          updatedAt: now,
        );

        await ref.read(expenseListNotifierProvider.notifier).addTransaction(sourceTx);
        await ref.read(expenseListNotifierProvider.notifier).addTransaction(destTx);
        await ref.read(accountsProvider.notifier).loadAccounts();
      } else {
        final transaction = Transaction(
          id: const Uuid().v4(),
          userId: userId,
          accountId: _selectedAccountId,
          categoryId: _selectedCategoryId,
          paymentMethodId: _selectedPaymentMethodId,
          type: _type,
          amount: intAmount,
          currency: auth.user?.currency ?? 'INR',
          merchant: _merchantController.text.trim().isNotEmpty ? _merchantController.text.trim() : null,
          description: finalDescription.isNotEmpty ? finalDescription : null,
          date: _selectedDate,
          source: 'ai_nlp',
          isRecurring: false,
          confidenceScore: widget.result.confidence,
          syncStatus: 'pending',
          createdAt: now,
          updatedAt: now,
        );

        await ref.read(expenseListNotifierProvider.notifier).addTransaction(transaction);
      }

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

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0066FF),
              onPrimary: Colors.white,
              surface: Color(0xFF0A0A0A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final categories = categoriesAsync.maybeWhen(data: (c) => c, orElse: () => <Category>[]);
    final paymentMethods = paymentMethodsAsync.maybeWhen(data: (p) => p, orElse: () => <PaymentMethod>[]);
    final accounts = accountsAsync.maybeWhen(data: (a) => a.where((x) => x.isActive == true).toList(), orElse: () => <Account>[]);

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      if (widget.result.accountName != null) {
        final match = accounts.firstWhere(
          (a) => a.name.toLowerCase().contains(widget.result.accountName!.toLowerCase()) || 
                 widget.result.accountName!.toLowerCase().contains(a.name.toLowerCase()),
          orElse: () => accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first),
        );
        _selectedAccountId = match.id;
      } else {
        final defaultAcc = accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
        _selectedAccountId = defaultAcc.id;
      }
    }

    if (_type == 'transfer' && _selectedTransferToAccountId == null && accounts.isNotEmpty) {
      if (widget.result.transferToAccountName != null) {
        final match = accounts.firstWhere(
          (a) => a.name.toLowerCase().contains(widget.result.transferToAccountName!.toLowerCase()) || 
                 widget.result.transferToAccountName!.toLowerCase().contains(a.name.toLowerCase()),
          orElse: () => accounts.firstWhere((a) => a.id != _selectedAccountId, orElse: () => accounts.first),
        );
        _selectedTransferToAccountId = match.id;
      } else {
        final otherAcc = accounts.firstWhere((a) => a.id != _selectedAccountId, orElse: () => accounts.first);
        _selectedTransferToAccountId = otherAcc.id;
      }
    }

    // Filter payment methods based on selected account type
    List<PaymentMethod> filteredMethods = [];
    if (_selectedAccountId != null && accounts.isNotEmpty) {
      final activeAcc = accounts.firstWhere((a) => a.id == _selectedAccountId, orElse: () => accounts.first);
      filteredMethods = _getAvailablePaymentMethodsForType(activeAcc.type, paymentMethods);

      if (_selectedPaymentMethodId == null && filteredMethods.isNotEmpty) {
        if (widget.result.paymentMethodName != null) {
          final match = filteredMethods.firstWhere(
            (pm) => pm.name.toLowerCase() == widget.result.paymentMethodName!.toLowerCase(),
            orElse: () => filteredMethods.first,
          );
          _selectedPaymentMethodId = match.id;
        } else {
          _selectedPaymentMethodId = filteredMethods.first.id;
        }
      } else if (_selectedPaymentMethodId != null && filteredMethods.isNotEmpty && !filteredMethods.any((pm) => pm.id == _selectedPaymentMethodId)) {
        _selectedPaymentMethodId = filteredMethods.first.id;
      }
    }

    if (_selectedCategoryId == null && categories.isNotEmpty) {
      final match = categories.firstWhere(
        (c) => c.name.toLowerCase() == widget.result.category.toLowerCase(),
        orElse: () => categories.first,
      );
      _selectedCategoryId = match.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Extracted Details',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Confidence: ${(widget.result.confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
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

            // Segmented selector
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Expense')),
                    selected: _type == 'expense',
                    onSelected: (val) => setState(() {
                      _type = 'expense';
                      _selectedCategoryId = null;
                    }),
                    selectedColor: const Color(0xFFFF3B30).withOpacity(0.2),
                    backgroundColor: Colors.white.withOpacity(0.04),
                    labelStyle: TextStyle(color: _type == 'expense' ? const Color(0xFFFF3B30) : Colors.white60),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Income')),
                    selected: _type == 'income',
                    onSelected: (val) => setState(() {
                      _type = 'income';
                      _selectedCategoryId = null;
                    }),
                    selectedColor: const Color(0xFF00E5FF).withOpacity(0.2),
                    backgroundColor: Colors.white.withOpacity(0.04),
                    labelStyle: TextStyle(color: _type == 'income' ? const Color(0xFF00E5FF) : Colors.white60),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Transfer')),
                    selected: _type == 'transfer',
                    onSelected: (val) => setState(() {
                      _type = 'transfer';
                      _selectedCategoryId = null;
                    }),
                    selectedColor: const Color(0xFFFFB703).withOpacity(0.2),
                    backgroundColor: Colors.white.withOpacity(0.04),
                    labelStyle: TextStyle(color: _type == 'transfer' ? const Color(0xFFFFB703) : Colors.white60),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount field
            const Text('AMOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.payments, color: Color(0xFF00E5FF)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Source account & Destination Account (For Transfer)
            if (_type == 'transfer') ...[
              const Text('FROM ACCOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                dropdownColor: const Color(0xFF050505),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF00E5FF)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: accounts.map((a) {
                  return DropdownMenuItem<String>(
                    value: a.id,
                    child: Text('${a.name} (₹${(a.balance / 100.0).toStringAsFixed(0)})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedAccountId = val;
                    if (_selectedAccountId == _selectedTransferToAccountId) {
                      _selectedTransferToAccountId = null; // Reset dest
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              const Text('TO ACCOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTransferToAccountId,
                dropdownColor: const Color(0xFF050505),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.swap_horiz, color: Color(0xFFFFB703)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: accounts.where((a) => a.id != _selectedAccountId).map((a) {
                  return DropdownMenuItem<String>(
                    value: a.id,
                    child: Text('${a.name} (₹${(a.balance / 100.0).toStringAsFixed(0)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedTransferToAccountId = val),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Financial Account Dropdown
              const Text('FINANCIAL ACCOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                dropdownColor: const Color(0xFF050505),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF00E5FF)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: accounts.map((a) {
                  return DropdownMenuItem<String>(
                    value: a.id,
                    child: Text('${a.name} (₹${(a.balance / 100.0).toStringAsFixed(0)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
              ),
              const SizedBox(height: 16),

              // Payment Method
              if (filteredMethods.isNotEmpty) ...[
                const Text('PAYMENT METHOD', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethodId,
                  dropdownColor: const Color(0xFF050505),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF00E5FF)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.03),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  items: filteredMethods.map((pm) {
                    return DropdownMenuItem<String>(
                      value: pm.id,
                      child: Text(pm.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedPaymentMethodId = val),
                ),
                const SizedBox(height: 16),
              ],

              // Category Selector
              const Text('CATEGORY', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                dropdownColor: const Color(0xFF050505),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.folder, color: Color(0xFF00E5FF)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: categories.where((c) => c.type == _type).map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 16),

              // Merchant
              const Text('MERCHANT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _merchantController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.storefront, color: Color(0xFF00E5FF)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Note / Description
            const Text('NOTE / DESCRIPTION', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.description, color: Color(0xFF00E5FF)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Date selector
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DATE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(_selectedDate),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const Icon(Icons.calendar_today, color: Color(0xFF00E5FF), size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TIME', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _timeController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. 14:30',
                          hintStyle: const TextStyle(color: Colors.white24),
                          prefixIcon: const Icon(Icons.access_time, color: Colors.white54, size: 16),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.03),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Collapsible Receipt Details Section
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text(
                  'Additional Receipt Details',
                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                leading: const Icon(Icons.receipt_long, color: Color(0xFF00E5FF), size: 20),
                childrenPadding: EdgeInsets.zero,
                tilePadding: EdgeInsets.zero,
                children: [
                  const Text('ADDRESS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.white54, size: 16),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('INVOICE NUMBER', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _invoiceController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.03),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('RECEIPT NUMBER', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _receiptNumController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.03),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TAX', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _taxController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.03),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DISCOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _discountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.03),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TIPS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _tipsController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.03),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Purchased Items list
            if (_items.isNotEmpty) ...[
              const Text('PURCHASED ITEMS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                padding: const EdgeInsets.all(12),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (context, idx) => const Divider(color: Colors.white10),
                  itemBuilder: (context, idx) {
                    final item = _items[idx];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                'Qty: ${item.quantity} | Unit: ₹${item.unitPrice.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${(item.quantity * item.unitPrice - item.discount).toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),

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
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('CONFIRM & SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
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
  String _statusText = 'Listening...';
  bool _isTransitioning = false;

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

  void _finishAndProcess(String text) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    // Stop listening so it updates state
    ref.read(voiceServiceProvider.notifier).stopListening();

    setState(() {
      _statusText = 'Processing...';
    });
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _statusText = 'Understanding...';
    });
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      Navigator.pop(context, text);
    }
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

    // Listen for automatic speech termination
    ref.listen<VoiceState>(voiceServiceProvider, (previous, next) {
      if (previous != null && previous.isListening && !next.isListening && _currentText.trim().isNotEmpty) {
        _finishAndProcess(_currentText);
      }
    });

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

                    if (voiceState.isListening && !_isTransitioning) ...[
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
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusText,
                        style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ] else if (_isTransitioning) ...[
                      const CircularProgressIndicator(color: Color(0xFF00E5FF)),
                      const SizedBox(height: 16),
                      Text(
                        _statusText,
                        style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ] else ...[
                      Text(
                        hasError ? 'Not Available' : 'Initializing...',
                        style: const TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],

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
                    if (voiceState.isListening && !_isTransitioning)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.stop),
                        label: const Text('STOP & PROCESS', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _finishAndProcess(_currentText);
                        },
                      )
                    else ...[
                      if (hasError && !_isTransitioning) ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () {
                            _finishAndProcess('Spent 450 rupees on dinner yesterday at Pizza Hut');
                          },
                          child: const Text('SIMULATE SPEECH INPUT', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!_isTransitioning)
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

void _showEnterOpeningBalanceDialog(BuildContext context, WidgetRef ref, Account account) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0F1A1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
        ),
        title: const Text(
          'Set Opening Balance',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter opening balance for ${account.displayTitle}:',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.02),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                 ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              final double? doubleVal = double.tryParse(text);
              if (doubleVal == null || doubleVal < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              Navigator.pop(context);
              final db = ref.read(databaseProvider);
              final centsVal = (doubleVal * 100).round();
              await db.accountDao.updateAccount(account.copyWith(
                openingBalance: Value(centsVal),
                isEstimated: false,
              ));
              await BalanceEngine(db).recalculateAllBalances();
              ref.invalidate(accountsProvider);
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}
