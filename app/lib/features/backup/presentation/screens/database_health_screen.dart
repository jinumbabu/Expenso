import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/backup_provider.dart';
import '../../../../shared/widgets/glass_card.dart';

class DatabaseHealthScreen extends ConsumerStatefulWidget {
  const DatabaseHealthScreen({super.key});

  @override
  ConsumerState<DatabaseHealthScreen> createState() => _DatabaseHealthScreenState();
}

class _DatabaseHealthScreenState extends ConsumerState<DatabaseHealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupNotifierProvider.notifier).checkDbHealth();
    });
  }

  IconData _getIconForCategory(String key) {
    switch (key) {
      case 'SQLite Integrity':
        return Icons.verified_user_outlined;
      case 'Foreign Keys':
        return Icons.vpn_key_outlined;
      case 'Accounts':
        return Icons.account_balance_outlined;
      case 'Categories':
        return Icons.category_outlined;
      case 'Transactions':
        return Icons.swap_horiz_outlined;
      case 'Budgets':
        return Icons.pie_chart_outline_outlined;
      case 'Credit Cards':
        return Icons.credit_card_outlined;
      case 'Loans':
        return Icons.monetization_on_outlined;
      case 'Goals':
        return Icons.track_changes_outlined;
      case 'SMS Drafts':
        return Icons.sms_outlined;
      default:
        return Icons.dns_outlined;
    }
  }

  void _showRepairReportSheet(BuildContext context, dynamic report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white10),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Repair Execution Report',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReportSummaryCard(context, report),
                        const SizedBox(height: 20),
                        Text(
                          'Violations Detected (${report.violationsFound.length})',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (report.violationsFound.isEmpty)
                          const Text(
                            'No violations found.',
                            style: TextStyle(color: Colors.white38),
                          )
                        else
                          ...report.violationsFound.map<Widget>((v) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        v,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        const SizedBox(height: 20),
                        Text(
                          'Actions Executed (${report.actionsTaken.length})',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (report.actionsTaken.isEmpty)
                          const Text(
                            'No repair actions were required.',
                            style: TextStyle(color: Colors.white38),
                          )
                        else
                          ...report.actionsTaken.map<Widget>((a) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        a,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportSummaryCard(BuildContext context, dynamic report) {
    final bytesSaved = report.bytesSaved as int;
    final sizeSavedText = bytesSaved > 1024 
        ? '${(bytesSaved / 1024).toStringAsFixed(1)} KB' 
        : '$bytesSaved bytes';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Initial Integrity', report.initialIntegrityPass ? 'PASS' : 'FAIL', report.initialIntegrityPass),
          const Divider(color: Colors.white10, height: 16),
          _buildSummaryRow('Initial Foreign Keys', report.initialFkPass ? 'PASS' : 'FAIL', report.initialFkPass),
          const Divider(color: Colors.white10, height: 16),
          _buildSummaryRow('Recovered Database Space', sizeSavedText, true),
          const Divider(color: Colors.white10, height: 16),
          _buildSummaryRow('Final Integrity Check', report.finalIntegrityPass ? 'PASS' : 'FAIL', report.finalIntegrityPass),
          const Divider(color: Colors.white10, height: 16),
          _buildSummaryRow('Final Foreign Keys Check', report.finalFkPass ? 'PASS' : 'FAIL', report.finalFkPass),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool pass) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(
          value,
          style: TextStyle(
            color: pass ? Colors.green : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(backupNotifierProvider);
    final health = state.dbHealthStatus;
    
    // Evaluate overall health
    bool allPass = health.values.every((val) => val == true);
    
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Database Health Checker'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(backupNotifierProvider.notifier).checkDbHealth();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing database health status...')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background soft color gradient glow
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: allPass 
                    ? Colors.green.withOpacity(0.15) 
                    : Colors.redAccent.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withOpacity(0.1),
              ),
            ),
          ),
          SafeArea(
            child: state.isLoading 
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Running Database Repair...',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // GlassCard Status Header
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: allPass 
                                        ? Colors.green.withOpacity(0.2) 
                                        : Colors.amber.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    allPass ? Icons.check_circle : Icons.warning,
                                    color: allPass ? Colors.green : Colors.amber,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        allPass ? 'Database Status: SECURE' : 'Database Status: ISSUES FOUND',
                                        style: TextStyle(
                                          color: allPass ? Colors.green : Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        allPass 
                                            ? 'All SQLite integrity checks and foreign key constraints passed.' 
                                            : 'Orphan records or constraint violations detected in the database.',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Title
                        const Text(
                          'Health Checks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // List of items
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: health.length,
                          itemBuilder: (context, index) {
                            final key = health.keys.elementAt(index);
                            final pass = health[key] ?? false;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    _getIconForCategory(key),
                                    color: Colors.purpleAccent,
                                  ),
                                  title: Text(
                                    key,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: pass 
                                          ? Colors.green.withOpacity(0.1) 
                                          : Colors.redAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: pass 
                                            ? Colors.green.withOpacity(0.3) 
                                            : Colors.redAccent.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      pass ? 'PASS' : 'FAIL',
                                      style: TextStyle(
                                        color: pass ? Colors.green : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Repair Actions
                        ElevatedButton.icon(
                          onPressed: () async {
                            final report = await ref
                                .read(backupNotifierProvider.notifier)
                                .runDatabaseRepair();
                            if (report != null && mounted) {
                              _showRepairReportSheet(context, report);
                            }
                          },
                          icon: const Icon(Icons.build_circle_outlined, color: Colors.white),
                          label: const Text('Repair Database & Rebuild Indexes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
