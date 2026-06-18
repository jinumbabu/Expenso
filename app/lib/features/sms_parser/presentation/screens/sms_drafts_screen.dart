import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/sms_parser_provider.dart';
import '../../../../core/database/app_database.dart';

class SmsDraftsScreen extends ConsumerWidget {
  const SmsDraftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(transactionDraftsStreamProvider);
    final scannerState = ref.watch(smsScannerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF002B24), Color(0xFF050F0E), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Screen Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'SMS Alerts & Drafts',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logo_dev, color: Colors.tealAccent),
                      tooltip: 'Simulate/Test SMS',
                      onPressed: () => _showMockSmsDialog(context, ref),
                    ),
                  ],
                ),
              ),

              // Status and Scanning Actions
              if (scannerState.errorMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

              // Action Buttons: Scan Inbox
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent.shade400,
                          foregroundColor: const Color(0xFF00241F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: scannerState.isScanning
                            ? null
                            : () => ref.read(smsScannerProvider.notifier).scanInbox(),
                        icon: scannerState.isScanning
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00241F)),
                              )
                            : const Icon(Icons.sync_alt),
                        label: Text(
                          scannerState.isScanning ? 'SCANNING...' : 'SCAN SMS INBOX',
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Drafts List
              Expanded(
                child: draftsAsync.when(
                  data: (drafts) {
                    if (drafts.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: drafts.length,
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        return _buildDraftCard(context, ref, draft);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.teal)),
                  error: (err, stack) => Center(
                    child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                  ),
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
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: const Icon(Icons.textsms_outlined, size: 64, color: Colors.teal),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Pending Drafts',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Banking transaction alerts received via SMS will be parsed locally and appear here as drafts for your approval.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftCard(BuildContext context, WidgetRef ref, TransactionDraft draft) {
    final amountFormatted = (draft.amount / 100.0).toStringAsFixed(2);
    final isExpense = draft.type == 'expense';
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(draft.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upper Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isExpense 
                        ? Colors.redAccent.withOpacity(0.08) 
                        : Colors.greenAccent.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExpense ? Icons.arrow_outward_rounded : Icons.call_received_rounded,
                    color: isExpense ? Colors.redAccent : Colors.greenAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.merchant ?? (isExpense ? 'General Expense' : 'Income Deposit'),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        draft.smsSender != null 
                            ? 'Sender: ${draft.smsSender} • $dateStr' 
                            : dateStr,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      if (draft.cardOrAccount != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Account/Card ending: ${draft.cardOrAccount}',
                            style: TextStyle(color: Colors.tealAccent.shade100, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Amount
                Text(
                  '${isExpense ? "-" : "+"}₹$amountFormatted',
                  style: TextStyle(
                    color: isExpense ? Colors.redAccent.shade100 : Colors.greenAccent.shade200,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // SMS snippet box
          if (draft.smsBody != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.02)),
              ),
              child: Text(
                draft.smsBody!,
                style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),

          // Bottom Action Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Dismiss Action
                TextButton.icon(
                  onPressed: () {
                    ref.read(smsScannerProvider.notifier).dismissDraft(draft.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Draft transaction dismissed.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                  label: const Text('Dismiss', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ),
                const SizedBox(width: 8),

                // Approve Action
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.withOpacity(0.3),
                    foregroundColor: Colors.tealAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: Colors.teal.withOpacity(0.5)),
                  ),
                  onPressed: () {
                    // Navigate to transaction form with draftId
                    context.push('/expenses/add?draftId=${draft.id}');
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Review & Approve', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
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
