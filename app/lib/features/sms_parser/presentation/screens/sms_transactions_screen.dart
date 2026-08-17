import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/sms_parser_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/account_formatters.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../../core/services/sms_account_matcher.dart';
import '../../../../shared/widgets/glass_card.dart';

class SmsTransactionsScreen extends ConsumerWidget {
  const SmsTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(transactionDraftsStreamProvider);
    final scannerState = ref.watch(smsScannerProvider);
    final accounts = ref.watch(accountsProvider).value ?? [];
    final paymentMethods = ref.watch(paymentMethodsProvider).value ?? [];
    final savedCountAsync = ref.watch(savedSmsTransactionsCountProvider);

    final pendingCount = draftsAsync.value?.length ?? 0;
    final savedCount = savedCountAsync.value ?? 0;

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
              // Screen Header (Centered Title, Back Button Left)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SizedBox(
                  height: 64,
                  child: Stack(
                    children: [
                      const Center(
                        child: Text(
                          'SMS Transactions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: () => context.pop(),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.logo_dev, color: Colors.tealAccent),
                            tooltip: 'Simulate/Test SMS',
                            onPressed: () => _showMockSmsDialog(context, ref),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(color: Colors.white10, height: 1),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Scanner Status Alerts
                    if (scannerState.errorMessage != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                scannerState.errorMessage!,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Section 1: SMS Transaction Scanner Card
                    _buildScannerControlCard(context, ref, scannerState),

                    const SizedBox(height: 20),

                    // Section 2: Stats Summary Card
                    _buildStatsSummaryCard(scannerState, pendingCount, savedCount),

                    const SizedBox(height: 24),

                    // Section 3: Pending transactions header and bulk actions
                    _buildPendingHeaderRow(context, ref, draftsAsync),

                    const SizedBox(height: 12),

                    // List of drafts or empty state
                    draftsAsync.when(
                      data: (drafts) {
                        if (drafts.isEmpty) {
                          return _buildEmptyState();
                        }
                        return Column(
                          children: drafts.map((draft) {
                            return _buildDraftCard(context, ref, draft, accounts, paymentMethods);
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                        ),
                      ),
                      error: (err, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                        ),
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

  Widget _buildScannerControlCard(BuildContext context, WidgetRef ref, SmsScannerState scannerState) {
    final permissionGranted = scannerState.smsPermissionStatus.isGranted;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SMS Transaction Scanner',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Automatically scan supported SMS messages for financial transactions.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (!permissionGranted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SMS Access Required',
                    style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Expenso AI needs SMS access to detect financial transactions.',
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => ref.read(smsScannerProvider.notifier).requestSmsPermission(),
              child: const Text('Allow SMS Access', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            Row(
              children: [
                const Text(
                  'SMS Access',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '✓ Enabled',
                    style: TextStyle(color: Color(0xFF00FF88), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: scannerState.isScanning
                  ? null
                  : () => ref.read(smsScannerProvider.notifier).scanInbox(),
              icon: scannerState.isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync_alt, size: 18),
              label: Text(
                scannerState.isScanning ? 'Scanning SMS...' : 'Scan SMS',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatsSummaryCard(SmsScannerState scannerState, int pendingCount, int savedCount) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SCAN STATUS',
            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('SMS Scanned', '${scannerState.scannedSmsCount}'),
              _buildStatItem('Transactions', '${scannerState.detectedTransactionsCount}'),
              _buildStatItem('Pending Review', '$pendingCount', color: const Color(0xFFFFCC00)),
              _buildStatItem('Saved', '$savedCount', color: const Color(0xFF00FF88)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color ?? const Color(0xFF00E5FF),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingHeaderRow(BuildContext context, WidgetRef ref, AsyncValue<List<TransactionDraft>> draftsAsync) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'PENDING TRANSACTIONS',
          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        draftsAsync.maybeWhen(
          data: (drafts) {
            if (drafts.isEmpty) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _handleApproveAll(context, ref),
                  child: const Text('Approve All', style: TextStyle(color: Color(0xFF00FF88), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => _handleDeleteAll(context, ref),
                  child: const Text('Delete All', style: TextStyle(color: Color(0xFFFF3B30), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.015),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: const Icon(Icons.textsms_outlined, size: 48, color: Colors.teal),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Pending Transactions',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Detected transactions should appear here\nfor user review.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantLogo(String merchantName) {
    final firstLetter = merchantName.isNotEmpty ? merchantName[0].toUpperCase() : 'M';
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0066FF).withOpacity(0.85),
            const Color(0xFF00E5FF).withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Map<String, String> _detectDraftAccountAndPm(
    TransactionDraft draft,
    List<Account> accounts,
    List<PaymentMethod> paymentMethods,
  ) {
    final smsRaw = draft.smsBody ?? draft.description ?? '';
    final matchResult = SmsAccountMatcher.matchAccount(
      smsText: smsRaw,
      existingAccounts: accounts,
      cardOrAccount: draft.cardOrAccount,
      sender: draft.smsSender,
    );

    final String accountName = matchResult.matchedAccount != null
        ? matchResult.matchedAccount!.displayTitle
        : matchResult.displayTitle;
    final String accountType = matchResult.matchedAccount != null
        ? matchResult.matchedAccount!.type
        : matchResult.accountType;

    return {
      'accountName': accountName,
      'accountType': accountType,
      'paymentMethod': matchResult.paymentMethod,
      'bankName': matchResult.matchedAccount?.bankName ?? matchResult.bankName,
    };
  }

  Widget _buildDraftCard(
    BuildContext context,
    WidgetRef ref,
    TransactionDraft draft,
    List<Account> accounts,
    List<PaymentMethod> paymentMethods,
  ) {
    final amountFormatted = (draft.amount / 100.0).toStringAsFixed(2);
    final isExpense = draft.type == 'expense';
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(draft.date);
    final merchantName = draft.merchant ?? (isExpense ? 'General Expense' : 'Income Deposit');
    
    final detected = _detectDraftAccountAndPm(draft, accounts, paymentMethods);
    final suggestedCategory = draft.category ?? (isExpense ? 'Shopping' : 'Salary');
    final confidenceScore = ((draft.confidenceScore ?? 0.85) * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (draft.matchingTransactionId != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Matches a manual entry. Link them?',
                      style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref.read(smsScannerProvider.notifier).linkDraftToManual(draft.id, draft.matchingTransactionId!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Linked draft to manual transaction successfully!')),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'LINK & APPROVE',
                      style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          // Upper Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMerchantLogo(merchantName),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchantName,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${detected["bankName"]} • $dateStr',
                        style: const TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${isExpense ? "-" : "+"}₹$amountFormatted',
                  style: TextStyle(
                    color: isExpense ? const Color(0xFFFF3B30) : const Color(0xFF00FF88),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // AI suggested tags/chips row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.psychology_outlined, size: 12, color: Color(0xFF00E5FF)),
                      const SizedBox(width: 4),
                      Text(
                        '$suggestedCategory ($confidenceScore%)',
                        style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        detected["accountType"] == 'credit_card' ? Icons.credit_card_rounded : Icons.account_balance_rounded, 
                        size: 12, 
                        color: const Color(0xFF0066FF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        detected["accountName"]!,
                        style: const TextStyle(color: Color(0xFF0066FF), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Text(
                    detected["paymentMethod"]!,
                    style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // SMS snippet box
          if (draft.smsBody != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.03)),
              ),
              child: Text(
                draft.smsBody!,
                style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic, height: 1.4),
              ),
            ),

          // Bottom Action Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ref.read(smsScannerProvider.notifier).dismissDraft(draft.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Draft transaction dismissed.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    context.push('/expenses/add?draftId=${draft.id}');
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    draft.matchingTransactionId != null ? 'Review & Link' : 'Review & Approve',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleApproveAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0C1918),
        title: const Text('Approve All Drafts?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to approve and import all pending SMS drafts?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              Navigator.pop(context);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                ),
              );

              final summary = await ref.read(smsScannerProvider.notifier).approveAllDrafts();
              
              if (context.mounted) {
                Navigator.pop(context); // Dismiss loading
                
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF0C1918),
                    title: const Text('Sync Completed', style: TextStyle(color: Colors.white)),
                    content: Text(
                      'Imported ${summary["imported"]} transactions.\n${summary["skipped"]} skipped as duplicate.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK', style: TextStyle(color: Colors.tealAccent)),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Approve All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0C1918),
        title: const Text('Delete All Drafts?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to permanently delete all pending SMS drafts?',
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
              await ref.read(smsScannerProvider.notifier).deleteAllDrafts();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All pending drafts deleted.'),
                    backgroundColor: Color(0xFF0C1918),
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

  void _showMockSmsDialog(BuildContext context, WidgetRef ref) {
    final Map<String, String> templates = {
      'HDFC UPI Debit (Rs. 150)': 'Dear Customer, Rs 150.00 debited from A/c XX1234 on 17-Jun-26 by UPI Ref 1234567. Info: TEA STALL.',
      'ICICI Card Spend (Rs. 2,500)': 'INR 2,500.00 spent on Credit Card ending 5678 at AMAZON INDIA on 17-Jun-26.',
      'SBI Salary Credit (Rs. 50,000)': 'Dear Customer, Rs 50,000.00 credited to A/c XX8901 on 17-Jun-26.',
      'ATM Cash Withdrawal (Rs. 1,000)': 'Your A/c ending in 4321 has been debited for Rs 1000.00 on 17-Jun-26 towards ATM withdrawal.',
    };

    final textController = TextEditingController();
    String selectedSender = 'HDFCBK';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0C1918),
              title: const Text('Simulate Banking SMS Alert', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text('Select an SMS format template:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 12),
                    ...templates.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              textController.text = e.value;
                              selectedSender = e.key.split(' ').first.toUpperCase();
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Text(e.key, style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    const Text('Or edit custom text:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter bank SMS message body here...',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.02),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () async {
                    if (textController.text.trim().isEmpty) return;
                    final success = await ref.read(smsScannerProvider.notifier).importMockSms(
                      selectedSender,
                      textController.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success 
                              ? 'SMS parsed and draft created!' 
                              : 'Failed to parse. Is this message a transaction alert?'),
                          backgroundColor: success ? Colors.teal.shade800 : Colors.red.shade900,
                        ),
                      );
                    }
                  },
                  child: const Text('Parse & Add', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
