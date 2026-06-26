import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../providers/sms_parser_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/sms_agent.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';

class DeveloperTestScreen extends ConsumerStatefulWidget {
  const DeveloperTestScreen({super.key});

  @override
  ConsumerState<DeveloperTestScreen> createState() => _DeveloperTestScreenState();
}

class _DeveloperTestScreenState extends ConsumerState<DeveloperTestScreen> {
  PermissionStatus _smsPermissionStatus = PermissionStatus.denied;
  int _smsTxCount = 0;
  String _testInput = '';
  SmsAgentResult? _testResult;
  bool _testAttempted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _loadStats();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.sms.status;
    if (mounted) {
      setState(() {
        _smsPermissionStatus = status;
      });
    }
  }

  Future<void> _loadStats() async {
    final db = ref.read(databaseProvider);
    final auth = ref.read(authProvider);
    final userId = auth.user?.id;
    if (userId == null) return;

    final txs = await db.transactionDao.getTransactionsForUser(userId);
    final smsCount = txs.where((t) => t.source == 'sms').length;

    if (mounted) {
      setState(() {
        _smsTxCount = smsCount;
      });
    }
  }

  Future<void> _triggerScan() async {
    await ref.read(smsScannerProvider.notifier).scanInbox();
    await _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync Scan Complete! Added ${ref.read(smsScannerProvider).newTransactionsCount} new transactions.'),
          backgroundColor: Colors.teal.shade800,
        ),
      );
    }
  }

  Future<void> _clearAllDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A1C),
        title: const Text('Completely Rebuild Database?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete all local transactions, accounts, categories, and settings, returning the app to a clean seed state. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.tealAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rebuild', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await db.clearAllData();
      
      // Seed default data again (simulating onCreate)
      final now = DateTime.now();
      // Drift database creates defaults on first load or migrator, we can force trigger migrations or clear.
      // Simply closing and letting openConnection handle it is one option, but clearAllData keeps the connection alive.
      // Let's seed categories and payment methods manually to ensure they are present!
      final defaultCategories = [
        {'name': 'Food', 'type': 'expense', 'icon': 'fastfood'},
        {'name': 'Fuel', 'type': 'expense', 'icon': 'local_gas_station'},
        {'name': 'Grocery', 'type': 'expense', 'icon': 'shopping_cart'},
        {'name': 'Utilities', 'type': 'expense', 'icon': 'receipt_long'},
        {'name': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag'},
        {'name': 'Entertainment', 'type': 'expense', 'icon': 'movie'},
        {'name': 'Salary', 'type': 'income', 'icon': 'payments'},
        {'name': 'Freelance', 'type': 'income', 'icon': 'work'},
        {'name': 'Investment', 'type': 'expense', 'icon': 'trending_up'},
        {'name': 'Transfer', 'type': 'transfer', 'icon': 'swap_horiz'},
      ];

      for (var cat in defaultCategories) {
        await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: const Uuid().v4(),
            userId: 'system',
            name: cat['name']!,
            type: cat['type']!,
            icon: Value(cat['icon']),
            isSystemDefault: const Value(true),
            createdAt: now,
          ),
        );
      }

      final defaultPaymentMethods = [
        {'name': 'Cash', 'type': 'cash'},
        {'name': 'UPI', 'type': 'upi'},
        {'name': 'Credit Card', 'type': 'card'},
        {'name': 'Debit Card', 'type': 'card'},
        {'name': 'Net Banking', 'type': 'bank'},
      ];

      for (var pm in defaultPaymentMethods) {
        await db.into(db.paymentMethods).insert(
          PaymentMethodsCompanion.insert(
            id: const Uuid().v4(),
            userId: 'system',
            name: pm['name']!,
            type: pm['type']!,
            createdAt: now,
          ),
        );
      }

      ref.invalidate(expenseListNotifierProvider);
      ref.invalidate(unrecognizedMessagesStreamProvider);
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database cleared & default seeds restored.'), backgroundColor: Colors.teal),
        );
      }
    }
  }

  Future<void> _exportLogs() async {
    final db = ref.read(databaseProvider);
    final agentLogs = await db.agentLogDao.getLogs(50);
    
    var logString = '--- EXPENSO AI TRANSACTION & AGENT LOGS ---\n\n';
    for (var log in agentLogs) {
      logString += '[${DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp)}] ';
      logString += '${log.agentName} | ${log.actionType} (Confidence: ${log.confidenceScore})\n';
      logString += 'Description: ${log.decisionDescription}\n\n';
    }

    await Clipboard.setData(ClipboardData(text: logString));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs copied to Clipboard!'), backgroundColor: Colors.teal),
      );
    }
  }

  void _runParserTest() async {
    final smsAgent = ref.read(smsAgentProvider);
    final result = await smsAgent.processSms(_testInput, DateTime.now());
    setState(() {
      _testResult = result;
      _testAttempted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(smsScannerProvider);
    final unrecognizedAsync = ref.watch(unrecognizedMessagesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DEVELOPER PANEL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
        backgroundColor: const Color(0xFF0F1A1C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050F11), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Section 1: System Metrics
            _buildSectionTitle('SMS PIPELINE STATUS'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow('Permission Status', _smsPermissionStatus.toString().replaceAll('PermissionStatus.', '').toUpperCase()),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStatRow('Total SMS Transactions', '$_smsTxCount'),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStatRow('Last Sync Timestamp', scannerState.lastSyncTime != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(scannerState.lastSyncTime!) : 'NEVER'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Actions
            _buildSectionTitle('OPERATIONS'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.withOpacity(0.2), foregroundColor: Colors.tealAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _triggerScan,
                    icon: const Icon(Icons.sync),
                    label: const Text('Scan Inbox', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.withOpacity(0.2), foregroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _exportLogs,
                    icon: const Icon(Icons.copy),
                    label: const Text('Export Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.2), foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _clearAllDatabase,
              icon: const Icon(Icons.refresh),
              label: const Text('Rebuild Database (Reset)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),

            // Section 3: Parser Playground
            _buildSectionTitle('PARSER PLAYGROUND'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Test regex parsing rules on any message text:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (val) => setState(() => _testInput = val),
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Paste bank SMS here...',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.02),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _runParserTest,
                    child: const Text('RUN TEST PARSE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (_testAttempted) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10, height: 16),
                    if (_testResult == null)
                      const Text('❌ Parsing Failed (Returned Null)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13))
                    else ...[
                      const Text('✅ Parsing Successful', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      _buildStatRow('Amount', '₹${_testResult!.amount}'),
                      _buildStatRow('Merchant', _testResult!.merchant),
                      _buildStatRow('Type', _testResult!.transactionType.toUpperCase()),
                      _buildStatRow('Account', _testResult!.account),
                      _buildStatRow('Bank', _testResult!.bank ?? 'NONE'),
                      _buildStatRow('Mode', _testResult!.paymentMode ?? 'NONE'),
                      _buildStatRow('Ref ID', _testResult!.referenceId ?? 'NONE'),
                      _buildStatRow('Balance', _testResult!.balance != null ? '₹${_testResult!.balance}' : 'NONE'),
                      _buildStatRow('Confidence', '${(_testResult!.confidence * 100).toStringAsFixed(0)}%'),
                    ],
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 4: Unrecognized Messages
            _buildSectionTitle('UNRECOGNIZED MESSAGES'),
            const SizedBox(height: 12),
            unrecognizedAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No unrecognized financial messages logged.', style: TextStyle(color: Colors.white38, fontSize: 12))));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.white.withOpacity(0.02),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.05))),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.sender ?? 'Unknown Sender', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(DateFormat('yyyy-MM-dd HH:mm').format(item.date), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item.body, style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                            const SizedBox(height: 8),
                            Text('Reason: ${item.failureReason ?? "Unknown error"}', style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.teal)),
              error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
