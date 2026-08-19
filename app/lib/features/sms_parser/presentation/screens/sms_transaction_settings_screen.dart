import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/sms_parser_provider.dart';
import '../../../../shared/widgets/glass_card.dart';

class SmsTransactionSettingsScreen extends ConsumerWidget {
  const SmsTransactionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(smsScannerProvider);
    final notifier = ref.read(smsScannerProvider.notifier);

    final permissionGranted = scannerState.smsPermissionStatus.isGranted;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SMS SETTINGS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0F1D), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            const Text(
              'Manage your SMS transaction scanner settings. Expenso uses secure local parsing to scan financial transactions directly on your device with complete privacy.',
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Section 1: SMS Access / Processing Toggle
            _buildSectionTitle('PROCESSING'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'SMS Processing',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Enable scanning and categorizing of transaction SMS alerts.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    value: scannerState.autoImportEnabled && permissionGranted,
                    onChanged: (val) {
                      if (!permissionGranted && val) {
                        notifier.requestSmsPermission();
                      } else {
                        notifier.toggleAutoImport(val);
                      }
                    },
                    activeColor: const Color(0xFF00E5FF),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Permissions Status
            _buildSectionTitle('SYSTEM PERMISSIONS'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SMS Permission',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (permissionGranted ? const Color(0xFF00FF88) : Colors.amber).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          permissionGranted ? '✓ Allowed' : '⚠ Not Granted',
                          style: TextStyle(
                            color: permissionGranted ? const Color(0xFF00FF88) : Colors.amberAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Android runtime permission is required to detect incoming bank alerts and reconcile transactions.',
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (scannerState.smsPermissionStatus.isPermanentlyDenied) {
                        openAppSettings();
                      } else {
                        await notifier.requestSmsPermission();
                      }
                    },
                    child: Text(
                      permissionGranted ? 'Manage Permission' : 'Grant Permission',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Automatic Scanning & Processing
            _buildSectionTitle('AUTOMATIC SCANNING'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Scan new SMS automatically',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Automatically process incoming transaction messages as they arrive in the background.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    value: scannerState.autoScanNewSms,
                    onChanged: (val) => notifier.toggleAutoScanNewSms(val),
                    activeColor: const Color(0xFF00E5FF),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 4: Proactive Alerts & Notifications
            _buildSectionTitle('NOTIFICATIONS'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Transaction notifications',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Receive instant notification alerts when new drafts or self-transfers are detected.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    value: scannerState.smsNotificationsEnabled,
                    onChanged: (val) => notifier.toggleSmsNotificationsEnabled(val),
                    activeColor: const Color(0xFF00E5FF),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}
