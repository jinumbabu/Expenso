import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/backup_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  String _formatSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 KB';
    final double kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final double mb = kb / 1024.0;
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Never Backed Up';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  void _confirmRestore(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
            SizedBox(width: 12),
            Text('Restore Backup', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'WARNING: Restoring will overwrite all local transactions, budgets, and settings with the backup version. This cannot be undone.\n\nAre you sure you want to proceed?',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.tealAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(backupNotifierProvider.notifier).restoreBackup();
            },
            child: const Text('Restore Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCloudBackup(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Backup', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete your cloud backup file? This will remove your file from the cloud server.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.tealAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(backupNotifierProvider.notifier).deleteBackup();
            },
            child: const Text('Delete Backup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupNotifierProvider);
    final authState = ref.watch(authProvider);
    final googleId = authState.user?.googleId ?? '';
    final isMock = googleId.startsWith('mock-') || googleId == 'google-id-token' || googleId.isEmpty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF002D27), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'Sync & Backup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Content Area
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    // Illustration / Icon Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.teal.withOpacity(0.08),
                              border: Border.all(color: Colors.teal.withOpacity(0.2)),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              size: 64,
                              color: Colors.tealAccent,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Secure Cloud Backups',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isMock
                                ? 'Simulated Secure Local Cloud Storage Active'
                                : 'Google Drive AppData Storage Active',
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Success Message Banner
                    if (state.successMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade900.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.tealAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                state.successMessage!,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Error Message Banner
                    if (state.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Glassmorphic Status Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BACKUP METADATA',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildMetadataRow(
                                icon: Icons.calendar_month_outlined,
                                label: 'Last Backed Up',
                                value: _formatDate(state.lastBackupDate),
                              ),
                              const Divider(color: Colors.white10, height: 24),
                              _buildMetadataRow(
                                icon: Icons.data_usage,
                                label: 'Backup Size',
                                value: _formatSize(state.backupSize),
                              ),
                              const Divider(color: Colors.white10, height: 24),
                              _buildMetadataRow(
                                icon: Icons.security,
                                label: 'Encryption Mode',
                                value: 'AES-256 (Local Key)',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Backup / Restore Actions
                    if (state.isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Backup Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent.shade700,
                              foregroundColor: const Color(0xFF00241F),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () => ref
                                .read(backupNotifierProvider.notifier)
                                .createBackup(),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.cloud_download),
                            label: const Text('Restore Backup'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: state.lastBackupDate == null
                                ? null
                                : () => _confirmRestore(context, ref),
                          ),
                          if (state.lastBackupDate != null) ...[
                            const SizedBox(height: 24),
                            TextButton.icon(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              label: const Text('Delete Cloud Backup', style: TextStyle(color: Colors.redAccent)),
                              onPressed: () => _confirmDeleteCloudBackup(context, ref),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 48),

                    // Information Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.tealAccent, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'All backups are locally encrypted using AES-256 with a unique key generated on your device. Expenso AI servers never see your key or your raw financial data.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildMetadataRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
