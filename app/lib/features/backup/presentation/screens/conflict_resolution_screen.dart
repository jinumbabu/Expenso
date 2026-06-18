import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/backup_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';

class ConflictResolutionScreen extends ConsumerWidget {
  const ConflictResolutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupNotifierProvider);
    final conflicts = state.conflicts;

    // Fetch categories and payment methods to map IDs to names
    final categoriesAsync = ref.watch(categoriesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    final categoriesMap = categoriesAsync.maybeWhen(
      data: (cats) => {for (var c in cats) c.id: c.name},
      orElse: () => <String, String>{},
    );

    final paymentMethodsMap = paymentMethodsAsync.maybeWhen(
      data: (pms) => {for (var pm in pms) pm.id: pm.name},
      orElse: () => <String, String>{},
    );

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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Resolve Conflicts',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${conflicts.length} Pending',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Conflict List
              Expanded(
                child: conflicts.isEmpty
                    ? _buildAllResolved(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: conflicts.length,
                        itemBuilder: (context, index) {
                          final conflict = conflicts[index];
                          return _buildConflictCard(context, ref, conflict, categoriesMap, paymentMethodsMap, index + 1, conflicts.length);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllResolved(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.withOpacity(0.08),
                border: Border.all(color: Colors.teal.withOpacity(0.2)),
              ),
              child: const Icon(Icons.check_circle_outline, size: 64, color: Colors.tealAccent),
            ),
            const SizedBox(height: 24),
            const Text(
              'All Conflicts Resolved!',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'All data is successfully merged, and your latest backup has been updated on the cloud.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade700,
                foregroundColor: const Color(0xFF00241F),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.pop(),
              child: const Text('Back to Sync Screen', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictCard(
    BuildContext context,
    WidgetRef ref,
    SyncConflict conflict,
    Map<String, String> categoriesMap,
    Map<String, String> paymentMethodsMap,
    int index,
    int total,
  ) {
    final local = conflict.local;
    final remote = conflict.remote;
    
    final localCat = local.categoryId != null ? (categoriesMap[local.categoryId] ?? 'Uncategorized') : 'Uncategorized';
    final remoteCat = remote.categoryId != null ? (categoriesMap[remote.categoryId] ?? 'Uncategorized') : 'Uncategorized';
    
    final localPm = local.paymentMethodId != null ? (paymentMethodsMap[local.paymentMethodId] ?? 'Default') : 'Default';
    final remotePm = remote.paymentMethodId != null ? (paymentMethodsMap[remote.paymentMethodId] ?? 'Default') : 'Default';

    final localAmount = (local.amount / 100.0).toStringAsFixed(2);
    final remoteAmount = (remote.amount / 100.0).toStringAsFixed(2);
    final localDate = DateFormat('MMM dd, yyyy • hh:mm a').format(local.date);
    final remoteDate = DateFormat('MMM dd, yyyy • hh:mm a').format(remote.date);
    
    final localUpdate = DateFormat('MMM dd, yyyy • hh:mm a').format(local.updatedAt);
    final remoteUpdate = DateFormat('MMM dd, yyyy • hh:mm a').format(remote.updatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Index Badge Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'CONFLICT $index OF $total: TRANSACTION EDIT COLLISION',
              style: TextStyle(color: Colors.redAccent.shade100, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // Two Columns (Local vs Remote)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Local Version Column
                Expanded(
                  child: _buildVersionColumn(
                    title: 'Local Version',
                    isLocal: true,
                    amount: localAmount,
                    merchant: local.merchant ?? 'N/A',
                    category: localCat,
                    pm: localPm,
                    desc: local.description ?? 'N/A',
                    date: localDate,
                    updatedAt: localUpdate,
                    diffFlags: {
                      'amount': local.amount != remote.amount,
                      'merchant': local.merchant != remote.merchant,
                      'category': local.categoryId != remote.categoryId,
                      'pm': local.paymentMethodId != remote.paymentMethodId,
                      'desc': local.description != remote.description,
                      'date': !local.date.isAtSameMomentAs(remote.date),
                    },
                  ),
                ),
                Container(
                  width: 1,
                  height: 340,
                  color: Colors.white10,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                // Remote Version Column
                Expanded(
                  child: _buildVersionColumn(
                    title: 'Remote Version',
                    isLocal: false,
                    amount: remoteAmount,
                    merchant: remote.merchant ?? 'N/A',
                    category: remoteCat,
                    pm: remotePm,
                    desc: remote.description ?? 'N/A',
                    date: remoteDate,
                    updatedAt: remoteUpdate,
                    diffFlags: {
                      'amount': local.amount != remote.amount,
                      'merchant': local.merchant != remote.merchant,
                      'category': local.categoryId != remote.categoryId,
                      'pm': local.paymentMethodId != remote.paymentMethodId,
                      'desc': local.description != remote.description,
                      'date': !local.date.isAtSameMomentAs(remote.date),
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Action Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.tealAccent,
                      side: BorderSide(color: Colors.teal.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => ref.read(backupNotifierProvider.notifier).resolveConflict(local.id, local),
                    child: const Text('Keep Local', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.shade700,
                      foregroundColor: const Color(0xFF00241F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => ref.read(backupNotifierProvider.notifier).resolveConflict(local.id, remote),
                    child: const Text('Keep Remote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionColumn({
    required String title,
    required bool isLocal,
    required String amount,
    required String merchant,
    required String category,
    required String pm,
    required String desc,
    required String date,
    required String updatedAt,
    required Map<String, bool> diffFlags,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isLocal ? Icons.phone_android : Icons.cloud_outlined,
              size: 16,
              color: isLocal ? Colors.tealAccent : Colors.tealAccent.shade100,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDiffItem(label: 'Amount', value: '₹$amount', hasDiff: diffFlags['amount'] ?? false),
        _buildDiffItem(label: 'Merchant', value: merchant, hasDiff: diffFlags['merchant'] ?? false),
        _buildDiffItem(label: 'Category', value: category, hasDiff: diffFlags['category'] ?? false),
        _buildDiffItem(label: 'Payment Method', value: pm, hasDiff: diffFlags['pm'] ?? false),
        _buildDiffItem(label: 'Description', value: desc, hasDiff: diffFlags['desc'] ?? false),
        _buildDiffItem(label: 'Date', value: date, hasDiff: diffFlags['date'] ?? false),
        const SizedBox(height: 12),
        const Text(
          'Last Edited',
          style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          updatedAt,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDiffItem({
    required String label,
    required String value,
    required bool hasDiff,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: hasDiff ? Colors.amberAccent : Colors.white,
              fontSize: 13,
              fontWeight: hasDiff ? FontWeight.bold : FontWeight.normal,
              backgroundColor: hasDiff ? Colors.amberAccent.withOpacity(0.08) : null,
            ),
          ),
        ],
      ),
    );
  }
}
