import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/security/audit_logger.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Privacy Mode State Notifier
final privacyModeProvider = StateNotifierProvider<PrivacyModeNotifier, String>((ref) {
  final auth = ref.watch(authProvider);
  final auditLogger = ref.watch(auditLoggerProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return PrivacyModeNotifier(auth.user?.id, auditLogger, secureStorage);
});

class PrivacyModeNotifier extends StateNotifier<String> {
  final String? _userId;
  final AuditLogger _auditLogger;
  final SecureStorageService _secureStorage;

  PrivacyModeNotifier(this._userId, this._auditLogger, this._secureStorage) : super('hybrid') {
    _load();
  }

  Future<void> _load() async {
    final mode = await _secureStorage.getPrivacyMode();
    if (mode != null) {
      state = mode;
    }
  }

  Future<void> setPrivacyMode(String mode) async {
    final oldMode = state;
    if (oldMode == mode) return;
    await _secureStorage.savePrivacyMode(mode);
    state = mode;

    await _auditLogger.logEvent(
      userId: _userId,
      eventType: 'privacy_mode_changed',
      eventCategory: 'security',
      description: 'Privacy mode updated from $oldMode to $mode.',
      metadata: {'old_mode': oldMode, 'new_mode': mode},
    );
  }
}

// Future Provider for AI Memory items
final aiMemoriesProvider = FutureProvider.autoDispose<List<AiMemoryItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return [];
  return await db.aiMemoryDao.getMemories(userId);
});

// Future Provider for Audit Logs
final auditLogsProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) async {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return [];
  return await db.auditLogDao.getLogsForUser(userId);
});

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  String _dbSize = 'Computing...';

  @override
  void initState() {
    super.initState();
    _loadDbSize();
  }

  Future<void> _loadDbSize() async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final file = File(p.join(supportDir.path, 'expenso_database.sqlite'));
      if (await file.exists()) {
        final bytes = await file.length();
        final kb = bytes / 1024;
        setState(() {
          if (kb > 1024) {
            _dbSize = '${(kb / 1024).toStringAsFixed(2)} MB';
          } else {
            _dbSize = '${kb.toStringAsFixed(2)} KB';
          }
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading db size: $e');
    }
    setState(() {
      _dbSize = 'Unknown';
    });
  }

  Future<void> _deleteMemoryItem(String id) async {
    final db = ref.read(databaseProvider);
    final auth = ref.read(authProvider);
    final auditLogger = ref.read(auditLoggerProvider);

    await db.aiMemoryDao.deleteMemory(id);
    ref.invalidate(aiMemoriesProvider);

    await auditLogger.logEvent(
      userId: auth.user?.id,
      eventType: 'ai_memory_item_deleted',
      eventCategory: 'security',
      description: 'Single AI memory item deleted by user.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memory item removed'), backgroundColor: Colors.teal),
      );
    }
  }

  Future<void> _wipeAllMemory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A1C),
        title: const Text('Wipe AI Memory?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete everything the AI assistant has learned about your behavior patterns and preferences. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.tealAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wipe', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      final auth = ref.read(authProvider);
      final auditLogger = ref.read(auditLoggerProvider);
      final userId = auth.user?.id;
      if (userId == null) return;

      await db.aiMemoryDao.clearMemories(userId);
      ref.invalidate(aiMemoriesProvider);

      await auditLogger.logEvent(
        userId: userId,
        eventType: 'ai_memory_wiped',
        eventCategory: 'security',
        description: 'Complete AI memory database wiped by user.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI memory completely wiped'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A1C),
        title: const Text('Clear Audit Logs?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will clear the history of all security, authentication, and sync events. Audit logs help maintain sync integrity.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.tealAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      final auth = ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) return;

      await db.auditLogDao.clearAllLogs(userId);
      ref.invalidate(auditLogsProvider);

      // Create a fresh entry so there's always at least one log indicating they were cleared
      final auditLogger = ref.read(auditLoggerProvider);
      await auditLogger.logEvent(
        userId: userId,
        eventType: 'audit_logs_cleared',
        eventCategory: 'security',
        description: 'Security audit logs cleared by user.',
      );
      ref.invalidate(auditLogsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit logs cleared'), backgroundColor: Colors.teal),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(privacyModeProvider);
    final memoriesAsync = ref.watch(aiMemoriesProvider);
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PRIVACY & SECURITY',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF002D27),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF002D27), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Section 1: Privacy Mode
            _buildSectionTitle('AI PRIVACY MODE'),
            const SizedBox(height: 12),
            _buildPrivacyModeCard(
              mode: 'local',
              title: 'Local (Private)',
              description: 'Bypasses cloud AI. Transactions are processed via local rule-based intelligence. Zero data leaves your device.',
              icon: Icons.shield_outlined,
              activeColor: Colors.tealAccent,
              selected: currentMode == 'local',
              onTap: () => ref.read(privacyModeProvider.notifier).setPrivacyMode('local'),
            ),
            const SizedBox(height: 12),
            _buildPrivacyModeCard(
              mode: 'hybrid',
              title: 'Hybrid (Recommended)',
              description: 'Attempts local parsing first. Connects to Gemini API only when complex queries need deeper cloud reasoning.',
              icon: Icons.hdr_strong_outlined,
              activeColor: Colors.purpleAccent,
              selected: currentMode == 'hybrid',
              onTap: () => ref.read(privacyModeProvider.notifier).setPrivacyMode('hybrid'),
            ),
            const SizedBox(height: 12),
            _buildPrivacyModeCard(
              mode: 'cloud',
              title: 'Cloud (Gemini)',
              description: 'Routes all transactions and assistant interactions to Gemini API directly for maximum depth and accuracy.',
              icon: Icons.cloud_queue_outlined,
              activeColor: Colors.amberAccent,
              selected: currentMode == 'cloud',
              onTap: () => ref.read(privacyModeProvider.notifier).setPrivacyMode('cloud'),
            ),

            const SizedBox(height: 32),

            // Section 2: AI Memory Transparency
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('AI MEMORY TRANSPARENCY'),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent, padding: EdgeInsets.zero),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text('Wipe Memory', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _wipeAllMemory,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: memoriesAsync.when(
                data: (memories) {
                  if (memories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No AI preferences or behavioral memories recorded yet.\nSpeak, scan receipts, or chat with AI to teach it.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: memories.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final item = memories[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(
                          item.memoryKey.toUpperCase(),
                          style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            item.memoryValue,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white30, size: 20),
                          onPressed: () => _deleteMemoryItem(item.id),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator(color: Colors.teal)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Section 3: Stored Data & Audit Logs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('DATA METRICS & AUDIT LOGS'),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent, padding: EdgeInsets.zero),
                  icon: const Icon(Icons.clear_all_outlined, size: 18),
                  label: const Text('Clear Logs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _clearLogs,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Database Encryption', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 2),
                      Text('Secure AES-256 local SQLCipher', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      _dbSize,
                      style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No security logs captured yet.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length > 5 ? 5 : logs.length, // show last 5 entries
                    separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      IconData logIcon = Icons.info_outline;
                      Color logColor = Colors.tealAccent;

                      if (log.eventCategory == 'authentication') {
                        logIcon = Icons.fingerprint;
                        logColor = Colors.purpleAccent;
                      } else if (log.eventCategory == 'backup') {
                        logIcon = Icons.cloud_sync_outlined;
                        logColor = Colors.amberAccent;
                      } else if (log.eventCategory == 'security') {
                        logIcon = Icons.lock_outline;
                        logColor = Colors.redAccent;
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: logColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(logIcon, color: logColor, size: 18),
                        ),
                        title: Text(
                          log.description,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            DateFormat('yyyy-MM-dd HH:mm:ss').format(log.createdAt),
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator(color: Colors.teal)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _buildPrivacyModeCard({
    required String mode,
    required String title,
    required String description,
    required IconData icon,
    required Color activeColor,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.08) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? activeColor.withOpacity(0.4) : Colors.white.withOpacity(0.05),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.05),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? activeColor.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: selected ? activeColor : Colors.white60, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: activeColor, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
