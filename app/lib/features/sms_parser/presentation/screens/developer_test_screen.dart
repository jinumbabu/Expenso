import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../providers/sms_parser_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/sms_agent.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../../core/services/duplicate_scanner.dart';

class DeveloperTestScreen extends ConsumerStatefulWidget {
  const DeveloperTestScreen({super.key});

  @override
  ConsumerState<DeveloperTestScreen> createState() => _DeveloperTestScreenState();
}

class _DeveloperTestScreenState extends ConsumerState<DeveloperTestScreen> {
  int _smsTxCount = 0;
  String _testInput = '';
  SmsAgentResult? _testResult;
  bool _testAttempted = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
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
      final parentCategories = [
        {'id': const Uuid().v4(), 'name': 'Food', 'type': 'expense', 'icon': 'fastfood', 'color': '0xFFFFA500'},
        {'id': const Uuid().v4(), 'name': 'Travel', 'type': 'expense', 'icon': 'flight', 'color': '0xFF0066FF'},
        {'id': const Uuid().v4(), 'name': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag', 'color': '0xFF8A2BE2'},
        {'id': const Uuid().v4(), 'name': 'Utilities', 'type': 'expense', 'icon': 'receipt_long', 'color': '0xFFFFB703'},
        {'id': const Uuid().v4(), 'name': 'Entertainment', 'type': 'expense', 'icon': 'movie', 'color': '0xFFFF3B30'},
        {'id': const Uuid().v4(), 'name': 'Salary', 'type': 'income', 'icon': 'payments', 'color': '0xFF00FF88'},
        {'id': const Uuid().v4(), 'name': 'Freelance', 'type': 'income', 'icon': 'work', 'color': '0xFF00FF88'},
        {'id': const Uuid().v4(), 'name': 'Investment', 'type': 'expense', 'icon': 'trending_up', 'color': '0xFF00E5FF'},
        {'id': const Uuid().v4(), 'name': 'Transfer', 'type': 'transfer', 'icon': 'swap_horiz', 'color': '0xFF6366F1'},
      ];

      for (var parent in parentCategories) {
        await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: parent['id']!,
            userId: 'system',
            name: parent['name']!,
            type: parent['type']!,
            icon: Value(parent['icon']),
            color: Value(parent['color']),
            isSystemDefault: const Value(true),
            createdAt: now,
          ),
        );
      }

      String getParentId(String name) => parentCategories.firstWhere((p) => p['name'] == name)['id']!;

      final subcategoriesData = [
        {'name': 'Restaurant', 'parent': 'Food', 'type': 'expense', 'icon': 'restaurant', 'color': '0xFFFFA500'},
        {'name': 'Cafe', 'parent': 'Food', 'type': 'expense', 'icon': 'coffee', 'color': '0xFFFFA500'},
        {'name': 'Snacks', 'parent': 'Food', 'type': 'expense', 'icon': 'bakery', 'color': '0xFFFFA500'},
        {'name': 'Fruits', 'parent': 'Food', 'type': 'expense', 'icon': 'spa', 'color': '0xFFFFA500'},
        
        {'name': 'Fuel', 'parent': 'Travel', 'type': 'expense', 'icon': 'local_gas_station', 'color': '0xFF0066FF'},
        {'name': 'Hotel', 'parent': 'Travel', 'type': 'expense', 'icon': 'hotel', 'color': '0xFF0066FF'},
        {'name': 'Flight', 'parent': 'Travel', 'type': 'expense', 'icon': 'flight', 'color': '0xFF0066FF'},
        {'name': 'Taxi', 'parent': 'Travel', 'type': 'expense', 'icon': 'local_taxi', 'color': '0xFF0066FF'},

        {'name': 'Grocery', 'parent': 'Shopping', 'type': 'expense', 'icon': 'shopping_cart', 'color': '0xFF8A2BE2'},
        {'name': 'Amazon', 'parent': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag', 'color': '0xFF8A2BE2'},
        {'name': 'Flipkart', 'parent': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag', 'color': '0xFF8A2BE2'},
        {'name': 'Clothes', 'parent': 'Shopping', 'type': 'expense', 'icon': 'checkroom', 'color': '0xFF8A2BE2'},

        {'name': 'Electricity Bill', 'parent': 'Utilities', 'type': 'expense', 'icon': 'electric_bolt', 'color': '0xFFFFB703'},
        {'name': 'Water Bill', 'parent': 'Utilities', 'type': 'expense', 'icon': 'water_drop', 'color': '0xFFFFB703'},
        {'name': 'Mobile Recharge', 'parent': 'Utilities', 'type': 'expense', 'icon': 'phone_android', 'color': '0xFFFFB703'},
        {'name': 'Internet', 'parent': 'Utilities', 'type': 'expense', 'icon': 'wifi', 'color': '0xFFFFB703'},
        {'name': 'Gas Bill', 'parent': 'Utilities', 'type': 'expense', 'icon': 'local_fire_department', 'color': '0xFFFFB703'},
      ];

      for (var sub in subcategoriesData) {
        await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: const Uuid().v4(),
            userId: 'system',
            name: sub['name']!,
            type: sub['type']!,
            parentId: Value(getParentId(sub['parent']!)),
            icon: Value(sub['icon']),
            color: Value(sub['color']),
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
      ref.invalidate(accountsProvider);
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
                  _buildStatRow('SMS Permission Status', scannerState.smsPermissionStatus.toString().replaceAll('PermissionStatus.', '').toUpperCase()),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStatRow('Notification Status', scannerState.notificationPermissionStatus.toString().replaceAll('PermissionStatus.', '').toUpperCase()),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStatRow('Auto-Import Status', scannerState.autoImportEnabled ? 'ENABLED' : 'DISABLED'),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStatRow('Last Request Timestamp', scannerState.lastPermissionRequestTime != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(scannerState.lastPermissionRequestTime!) : 'NEVER'),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStatRow('Inbox Accessibility', scannerState.isInboxAccessible ? 'ACCESSIBLE' : 'BLOCKED / NO ACCESS'),
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
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.2),
                foregroundColor: Colors.amberAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                final auth = ref.read(authProvider);
                final userId = auth.user?.id;
                if (userId == null) return;
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Colors.amberAccent),
                  ),
                );

                final scanner = ref.read(duplicateScannerProvider);
                final mergedCount = await scanner.scanAndCleanupDuplicates(userId);
                
                if (context.mounted) {
                  Navigator.pop(context); // Dismiss loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Duplicate Scan Completed! Merged $mergedCount duplicate transaction(s).'),
                      backgroundColor: Colors.amber.shade800,
                    ),
                  );
                  await _loadStats();
                }
              },
              icon: const Icon(Icons.cleaning_services_rounded),
              label: const Text('Run Duplicate Scanner', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.withOpacity(0.2),
                foregroundColor: Colors.purpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => context.push('/diagnostics'),
              icon: const Icon(Icons.speed_outlined),
              label: const Text('Open Cloud Diagnostics', style: TextStyle(fontWeight: FontWeight.bold)),
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
