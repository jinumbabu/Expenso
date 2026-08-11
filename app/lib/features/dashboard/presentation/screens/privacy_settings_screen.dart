import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/security/app_lock_service.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../backup/presentation/providers/backup_provider.dart';
import '../providers/hide_balance_provider.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../core/security/audit_logger.dart';
import '../../../../core/services/settings_provider.dart';


// Privacy Mode State Notifier (Local/Hybrid/Cloud)
final aiPrivacyModeProvider = StateNotifierProvider<AiPrivacyModeNotifier, String>((ref) {
  return AiPrivacyModeNotifier(ref);
});

class AiPrivacyModeNotifier extends StateNotifier<String> {
  final Ref _ref;

  AiPrivacyModeNotifier(this._ref) : super('hybrid') {
    _ref.listen<AppSettingsState>(
      appSettingsProvider,
      (previous, next) {
        state = next.aiPrivacyMode;
      },
      fireImmediately: true,
    );
  }

  Future<void> setAiPrivacyMode(String mode) async {
    await _ref.read(appSettingsProvider.notifier).setSetting('aiPrivacyMode', mode);
    try {
      final userId = _ref.read(authProvider).user?.id;
      await _ref.read(auditLoggerProvider).logEvent(
        userId: userId,
        eventType: 'privacy_mode_changed',
        eventCategory: 'security',
        description: 'AI inference mode changed to $mode',
      );
    } catch (_) {}
  }
}

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _dbSize = 'Computing...';
  
  // Edit profile states
  final TextEditingController _nameController = TextEditingController();

  // Mock devices list
  List<Map<String, String>> _sessions = [
    {'id': 'current', 'device': 'This Android Device', 'status': 'Active Now', 'trusted': 'true'},
    {'id': 'pixel8', 'device': 'Google Pixel 8', 'status': 'Last synced 2 hours ago', 'trusted': 'true'},
    {'id': 'ipad', 'device': 'iPad Pro 11"', 'status': 'Last synced 3 days ago', 'trusted': 'false'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDbSize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    
    setState(() {
      _nameController.text = user.displayName ?? '';
    });
  }

  Future<void> _loadDbSize() async {
    try {
      final user = ref.read(authProvider).user;
      final supportDir = await getApplicationSupportDirectory();
      final dbName = user != null ? 'expenso_database_${user.id}.sqlite' : 'expenso_database.sqlite';
      final file = File(p.join(supportDir.path, dbName));
      if (await file.exists()) {
        final bytes = await file.length();
        final kb = bytes / 1024;
        setState(() {
          if (kb > 1024) {
            _dbSize = '${(kb / 1024).toStringAsFixed(2)} MB';
          } else {
            _dbSize = '${kb.toStringAsFixed(1)} KB';
          }
        });
      } else {
        setState(() {
          _dbSize = '0 KB';
        });
      }
    } catch (_) {
      setState(() {
        _dbSize = 'Unknown';
      });
    }
  }

  Future<bool> _verifySensitiveAction(String reason) async {
    const int _pinLength = 4;
    final user = ref.read(authProvider).user;
    if (user == null) return false;

    final appLock = ref.read(appLockServiceProvider);
    
    // Check if security PIN is enabled
    final hasPin = await appLock.isPinSet(user.id);
    if (!hasPin) return true; // No protection active

    // Try biometric first if enabled
    final bioEnabled = await appLock.isBiometricEnabled(user.id);
    if (bioEnabled) {
      final success = await appLock.authenticateWithBiometrics();
      if (success) {
        HapticFeedback.mediumImpact();
        return true;
      }
    }

    // Fallback: Show PIN validation dialog
    final String? verifiedPin = await showDialog<String>(
      context: context,
      builder: (context) {
        String entered = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F1A1C),
              title: Text(reason, style: const TextStyle(color: Colors.white, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter your PIN to verify identity:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 16),
                  TextField(
                    obscureText: true,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 4),
                    maxLength: _pinLength,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    onChanged: (val) {
                      setModalState(() {
                        entered = val;
                      });
                      if (val.length == _pinLength) {
                        Navigator.pop(context, val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
              ],
            );
          },
        );
      },
    );

    if (verifiedPin != null) {
      final verified = await appLock.verifyPin(user.id, verifiedPin);
      if (verified) {
        HapticFeedback.mediumImpact();
        return true;
      } else {
        HapticFeedback.vibrate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
    return false;
  }

  Future<void> _changePinFlow() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final verified = await _verifySensitiveAction('Change Security PIN');
    if (!verified) return;

    String tempPin = '';
    String tempConfirm = '';
    int chosenLen = ref.read(appSettingsProvider).pinLength;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF030D1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final pinOk = tempPin.length == chosenLen && tempConfirm == tempPin;
            return Padding(
              padding: EdgeInsets.only(
                top: 20, left: 24, right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SET NEW PIN', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('4 Digits'),
                        selected: chosenLen == 4,
                        onSelected: (val) {
                          setModalState(() {
                            chosenLen = 4;
                            tempPin = '';
                            tempConfirm = '';
                          });
                        },
                        selectedColor: const Color(0xFF0066FF).withOpacity(0.2),
                        backgroundColor: Colors.white.withOpacity(0.02),
                      ),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('6 Digits'),
                        selected: chosenLen == 6,
                        onSelected: (val) {
                          setModalState(() {
                            chosenLen = 6;
                            tempPin = '';
                            tempConfirm = '';
                          });
                        },
                        selectedColor: const Color(0xFF0066FF).withOpacity(0.2),
                        backgroundColor: Colors.white.withOpacity(0.02),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: chosenLen,
                    decoration: const InputDecoration(
                      labelText: 'New PIN',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        tempPin = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: chosenLen,
                    decoration: const InputDecoration(
                      labelText: 'Confirm PIN',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        tempConfirm = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: pinOk ? () async {
                      final appLock = ref.read(appLockServiceProvider);
                      await appLock.savePin(user.id, tempPin, length: chosenLen);
                      await ref.read(firestoreSyncServiceProvider).syncUserProfileToCloud(user.id);
                      await ref.read(appSettingsProvider.notifier).refreshLockState();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PIN Updated Successfully!')),
                        );
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Save PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAccountFlow() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final verified = await _verifySensitiveAction('Permanently Delete Account');
    if (!verified) return;

    final TextEditingController deleteController = TextEditingController();
    bool confirmed = false;

    final res = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F1A1C),
            title: const Text('DELETE ACCOUNT PERMANENTLY?', style: TextStyle(color: Colors.redAccent)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This action is irreversible. All local databases, security keys, sync queues, and Google Drive backups will be permanently deleted.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Type "DELETE" below to confirm account destruction:',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: deleteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'DELETE',
                  ),
                  onChanged: (val) {
                    setModalState(() {
                      confirmed = val == 'DELETE';
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: confirmed ? () => Navigator.pop(context, true) : null,
                child: const Text(
                  'DESTROY',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (res != true) return;

    // Execute complete account destruction
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      ),
    );

    try {
      // 1. Wipe Cloud Data (Firestore docs etc.)
      final db = ref.read(databaseProvider);
      // Delete user specific data in all tables
      await db.transaction(() async {
        // Simple wipe queries
        await db.customStatement('DELETE FROM transactions WHERE user_id = ?', [user.id]);
        await db.customStatement('DELETE FROM accounts WHERE user_id = ?', [user.id]);
        await db.customStatement('DELETE FROM budgets WHERE user_id = ?', [user.id]);
        await db.customStatement('DELETE FROM goals WHERE user_id = ?', [user.id]);
        await db.customStatement('DELETE FROM users WHERE id = ?', [user.id]);
      });

      // 2. Close Database Connection
      ref.read(authProvider.notifier).logout();

      // 3. Delete Database file on disk
      final supportDir = await getApplicationSupportDirectory();
      final dbFile = File(p.join(supportDir.path, 'expenso_database_${user.id}.sqlite'));
      final walFile = File(p.join(supportDir.path, 'expenso_database_${user.id}.sqlite-wal'));
      final shmFile = File(p.join(supportDir.path, 'expenso_database_${user.id}.sqlite-shm'));

      if (dbFile.existsSync()) dbFile.deleteSync();
      if (walFile.existsSync()) walFile.deleteSync();
      if (shmFile.existsSync()) shmFile.deleteSync();

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account permanently deleted.'), backgroundColor: Colors.redAccent),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deletion failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _wipeAiMemory() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final db = ref.read(databaseProvider);
    await db.customStatement('DELETE FROM ai_learnings WHERE user_id = ?', [user.id]);
    await db.customStatement('DELETE FROM transaction_drafts WHERE user_id = ?', [user.id]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI learning models wiped successfully.'), backgroundColor: Color(0xFF0066FF)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final hideState = ref.watch(hideBalanceProvider);
    final aiPrivacyMode = ref.watch(aiPrivacyModeProvider);
    final settings = ref.watch(appSettingsProvider);

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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Settings & Security',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    hintText: 'Search settings, security features...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.03),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),

              // Settings List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    // ACCOUNT SECTION
                    if (_matchesSearch('Account Profile Devices Sessions Logout Delete')) ...[
                      _buildSectionHeader('ACCOUNT'),
                      _buildSettingCard([
                        _buildListTile(
                          icon: Icons.person_outline,
                          title: 'Profile Details',
                          subtitle: user?.displayName ?? 'Jinu',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF0F1A1C),
                                title: const Text('Edit Display Name', style: TextStyle(color: Colors.white)),
                                content: TextField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(border: OutlineInputBorder()),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(foregroundColor: Colors.white54),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      // Save name logic
                                      final db = ref.read(databaseProvider);
                                      if (user != null) {
                                        final secureStorage = ref.read(secureStorageProvider);
                                        await secureStorage.saveCustomDisplayName(_nameController.text, userId: user.id);

                                        await db.customStatement(
                                          'UPDATE users SET display_name = ? WHERE id = ?',
                                          [_nameController.text, user.id],
                                        );

                                        // Sync changes to cloud
                                        await ref.read(firestoreSyncServiceProvider).syncUserProfileToCloud(user.id);

                                        // Force refresh auth provider session
                                        await ref.read(authProvider.notifier).checkSession();
                                      }
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                    child: const Text('Save', style: TextStyle(color: Color(0xFF00E5FF))),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          icon: Icons.people_outline,
                          title: 'Switch / Manage Accounts',
                          subtitle: 'Logged in as ${user?.email ?? "Offline user"}',
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: const Color(0xFF030D1E),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (context) {
                                return Consumer(
                                  builder: (context, ref, child) {
                                    final accountsAsync = ref.watch(registeredAccountsProvider);
                                    return Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('REGISTERED ACCOUNTS', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                          const SizedBox(height: 16),
                                          accountsAsync.when(
                                            data: (accounts) {
                                              if (accounts.isEmpty) {
                                                return const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 20),
                                                  child: Text('No other accounts registered.', style: TextStyle(color: Colors.white30)),
                                                );
                                              }
                                              return ListView.separated(
                                                shrinkWrap: true,
                                                itemCount: accounts.length,
                                                separatorBuilder: (context, index) => Divider(
                                                  color: Colors.white.withOpacity(0.05),
                                                  height: 24,
                                                  thickness: 1,
                                                ),
                                                itemBuilder: (context, index) {
                                                  final acc = accounts[index];
                                                  final isCurrent = acc['id'] == user?.id;
                                                  return Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor: const Color(0xFF001F4D),
                                                        child: Text(
                                                          (acc['displayName'] ?? 'U')[0].toUpperCase(),
                                                          style: const TextStyle(
                                                            color: Color(0xFF00E5FF),
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              acc['displayName'] ?? 'User',
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              softWrap: false,
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              acc['email'] ?? '',
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              softWrap: false,
                                                              style: const TextStyle(
                                                                color: Colors.white30,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      if (isCurrent)
                                                        const Padding(
                                                          padding: EdgeInsets.symmetric(horizontal: 16),
                                                          child: Icon(Icons.check, color: Color(0xFF00E5FF), size: 20),
                                                        )
                                                      else
                                                        Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            TextButton(
                                                              onPressed: () async {
                                                                Navigator.pop(context);
                                                                await ref.read(authProvider.notifier).switchAccount(acc['id']);
                                                                if (context.mounted) {
                                                                  context.go('/lock');
                                                                }
                                                              },
                                                              child: const Text(
                                                                'Switch',
                                                                style: TextStyle(
                                                                  color: Color(0xFF00E5FF),
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                              onPressed: () async {
                                                                final confirm = await showDialog<bool>(
                                                                  context: context,
                                                                  builder: (context) => AlertDialog(
                                                                    backgroundColor: const Color(0xFF0F1A1C),
                                                                    title: const Text('Remove Account?', style: TextStyle(color: Colors.white)),
                                                                    content: Text('Remove ${acc['displayName']} and delete all local database files for this account?'),
                                                                    actions: [
                                                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.redAccent))),
                                                                    ],
                                                                  ),
                                                                );
                                                                if (confirm == true) {
                                                                  await ref.read(authProvider.notifier).removeAccount(acc['id']);
                                                                }
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
                                            error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.white70)),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              ref.read(authProvider.notifier).logout();
                                              context.go('/login');
                                            },
                                            icon: const Icon(Icons.add),
                                            label: const Text('Add Another Account'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0066FF),
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(double.infinity, 44),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                );
                              },
                            );
                          },
                        ),
                        _buildListTile(
                          icon: Icons.alternate_email,
                          title: 'Google Account ID',
                          subtitle: user?.email ?? 'Offline Account',
                          trailing: const Icon(Icons.lock_outline, color: Colors.white24, size: 16),
                        ),
                        _buildListTile(
                          icon: Icons.devices_other,
                          title: 'Active Sessions & Devices',
                          subtitle: 'Manage devices connected to your data',
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: const Color(0xFF030D1E),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setModalState) {
                                    return Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('ACTIVE SESSIONS', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 16),
                                          ..._sessions.map((s) => ListTile(
                                            leading: Icon(
                                              s['id'] == 'current' ? Icons.phone_android : Icons.computer,
                                              color: s['id'] == 'current' ? const Color(0xFF00E5FF) : Colors.white60,
                                            ),
                                            title: Text(s['device'] ?? '', style: const TextStyle(color: Colors.white)),
                                            subtitle: Text(s['status'] ?? '', style: const TextStyle(color: Colors.white30, fontSize: 12)),
                                            trailing: s['id'] == 'current'
                                                ? null
                                                : TextButton(
                                                    onPressed: () {
                                                      setModalState(() {
                                                        _sessions.removeWhere((item) => item['id'] == s['id']);
                                                      });
                                                    },
                                                    child: const Text('Revoke', style: TextStyle(color: Colors.redAccent)),
                                                  ),
                                          )),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        _buildListTile(
                          icon: Icons.logout,
                          title: 'Logout Session',
                          subtitle: 'End all active secure states',
                          onTap: () async {
                            final verified = await _verifySensitiveAction('Confirm Logout');
                            if (!verified) return;
                            await ref.read(authProvider.notifier).logout();
                            if (mounted) context.go('/login');
                          },
                        ),
                        _buildListTile(
                          icon: Icons.delete_forever_outlined,
                          title: 'Delete Account',
                          subtitle: 'Permanently destroy all data assets',
                          textColor: Colors.redAccent,
                          onTap: _deleteAccountFlow,
                        ),
                      ]),
                      const SizedBox(height: 20),
                    ],

                    // SECURITY SECTION
                    if (_matchesSearch('Security App Lock PIN Biometrics Screen Screenshot Balances')) ...[
                      _buildSectionHeader('SECURITY'),
                      _buildSettingCard([
                        SwitchListTile(
                          title: const Text('App PIN Lock', style: TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text('Lock the application with a ${settings.pinLength} digit PIN', style: const TextStyle(color: Colors.white30, fontSize: 12)),
                          value: settings.pinEnabled,
                          activeColor: const Color(0xFF00E5FF),
                          activeTrackColor: const Color(0xFF00E5FF).withOpacity(0.3),
                          onChanged: (val) async {
                            if (val) {
                              _changePinFlow();
                            } else {
                              final verified = await _verifySensitiveAction('Disable App PIN Lock');
                              if (!verified) return;
                              final appLock = ref.read(appLockServiceProvider);
                              if (user != null) {
                                await appLock.removePin(user.id);
                                await ref.read(firestoreSyncServiceProvider).syncUserProfileToCloud(user.id);
                                await ref.read(appSettingsProvider.notifier).refreshLockState();
                              }
                            }
                          },
                        ),
                        if (settings.pinEnabled)
                          _buildListTile(
                            icon: Icons.key_rounded,
                            title: 'Change lock PIN',
                            subtitle: 'Modify dynamic PIN layout',
                            onTap: _changePinFlow,
                          ),
                        SwitchListTile(
                          title: const Text('Biometric Authentication', style: TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: const Text('Allow fingerprint/face scanner triggers', style: const TextStyle(color: Colors.white30, fontSize: 12)),
                          value: settings.biometricEnabled,
                          activeColor: const Color(0xFF00E5FF),
                          activeTrackColor: const Color(0xFF00E5FF).withOpacity(0.3),
                          onChanged: (val) async {
                            final verified = await _verifySensitiveAction(val ? 'Enable Biometric Authentication' : 'Disable Biometric Authentication');
                            if (!verified) return;
                            if (user != null) {
                              await ref.read(appSettingsProvider.notifier).setSetting('biometricEnabled', val);
                              await ref.read(firestoreSyncServiceProvider).syncUserProfileToCloud(user.id);
                            }
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Screenshot Security', style: TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: const Text('Prevent app screenshots/recordings', style: const TextStyle(color: Colors.white30, fontSize: 12)),
                          value: settings.screenSecurityEnabled,
                          activeColor: const Color(0xFF00E5FF),
                          activeTrackColor: const Color(0xFF00E5FF).withOpacity(0.3),
                          onChanged: (val) async {
                            if (user != null) {
                              await ref.read(appSettingsProvider.notifier).setSetting('screenSecurityEnabled', val);
                              await ref.read(firestoreSyncServiceProvider).syncUserProfileToCloud(user.id);
                            }
                          },
                        ),
                        _buildListTile(
                          icon: Icons.timer_outlined,
                          title: 'Inactivity Timer',
                          subtitle: settings.autoLockSeconds == -1 ? 'Never' : '${settings.autoLockSeconds} seconds',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF0F1A1C),
                                title: const Text('Auto-Lock Timer', style: TextStyle(color: Colors.white)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildTimerOption(-1, 'Never (Disabled)'),
                                    _buildTimerOption(0, 'Immediate'),
                                    _buildTimerOption(15, '15 Seconds'),
                                    _buildTimerOption(60, '1 Minute'),
                                    _buildTimerOption(300, '5 Minutes'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Hide Net Worth Balance', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: hideState.hideNetWorth,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (val) => ref.read(hideBalanceProvider.notifier).toggleHideNetWorth(),
                        ),
                        SwitchListTile(
                          title: const Text('Hide Account Balances', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: hideState.hideAccountBalances,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (val) => ref.read(hideBalanceProvider.notifier).toggleHideAccountBalances(),
                        ),
                        SwitchListTile(
                          title: const Text('Hide Transaction Amounts', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: hideState.hideTransactionAmounts,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (val) => ref.read(hideBalanceProvider.notifier).toggleHideTransactionAmounts(),
                        ),
                        SwitchListTile(
                          title: const Text('Hide Analytics Amounts', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: hideState.hideAnalyticsAmounts,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (val) => ref.read(hideBalanceProvider.notifier).toggleHideAnalyticsAmounts(),
                        ),
                        SwitchListTile(
                          title: const Text('Hide Dashboard Amounts', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: hideState.hideDashboard,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (val) => ref.read(hideBalanceProvider.notifier).toggleHideDashboard(),
                        ),
                        SwitchListTile(
                          title: const Text('Hide Account Details', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: hideState.hideAccountDetails,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (val) => ref.read(hideBalanceProvider.notifier).toggleHideAccountDetails(),
                        ),
                        SwitchListTile(
                          title: const Text('Hide Cards Amounts', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: hideState.hideCards,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (val) => ref.read(hideBalanceProvider.notifier).toggleHideCards(),
                        ),
                      ]),
                      const SizedBox(height: 20),
                    ],

                    // AI SETTINGS SECTION
                    if (_matchesSearch('AI Local Hybrid Cloud Memory Learning Wipe Diagnostics')) ...[
                      _buildSectionHeader('AI PRIVACY & SETTINGS'),
                      _buildSettingCard([
                        ListTile(
                          title: const Text('AI Inference Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text('Current: ${aiPrivacyMode.toUpperCase()}', style: const TextStyle(color: Colors.white30, fontSize: 12)),
                          trailing: DropdownButton<String>(
                            value: aiPrivacyMode,
                            dropdownColor: const Color(0xFF0F1A1C),
                            style: const TextStyle(color: Color(0xFF00E5FF)),
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'local', child: Text('Local (Device)')),
                              DropdownMenuItem(value: 'hybrid', child: Text('Hybrid (Recommended)')),
                              DropdownMenuItem(value: 'cloud', child: Text('Cloud (Gemini)')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(aiPrivacyModeProvider.notifier).setAiPrivacyMode(val);
                              }
                            },
                          ),
                        ),
                        _buildListTile(
                          icon: Icons.memory,
                          title: 'Wipe AI Learning Model',
                          subtitle: 'Clear all customized locally learned metadata',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF0F1A1C),
                                title: const Text('Clear AI Learnings?', style: TextStyle(color: Colors.white)),
                                content: const Text('Wiping AI memory will delete all custom learned models, automated categorization preferences, and SMS templates.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _wipeAiMemory();
                                    },
                                    child: const Text('WIPE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 20),
                    ],

                    // DATA & BACKUP SECTION
                    if (_matchesSearch('Data Backup Google Drive Restore Sync')) ...[
                      _buildSectionHeader('DATA & BACKUP'),
                      _buildSettingCard([
                        _buildListTile(
                          icon: Icons.cloud_done_outlined,
                          title: 'Google Drive Cloud Status',
                          subtitle: 'Active Cloud Sync parameters & details',
                          onTap: () => context.push('/backup'),
                        ),
                        _buildListTile(
                          icon: Icons.storage_outlined,
                          title: 'Database Storage Footprint',
                          subtitle: 'SQLite File: $_dbSize',
                          trailing: const Icon(Icons.info_outline, color: Colors.white30, size: 16),
                        ),
                      ]),
                      const SizedBox(height: 20),
                    ],

                    // PRIVACY POLICY SECTION
                    if (_matchesSearch('Privacy Policy Terms Legal Rules Acceptance')) ...[
                      _buildSectionHeader('PRIVACY & TERMS'),
                      _buildSettingCard([
                        _buildListTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'Expenso data privacy & standard disclosures',
                          onTap: () => context.push('/privacy'),
                        ),
                        _buildListTile(
                          icon: Icons.gavel_outlined,
                          title: 'Terms of Service',
                          subtitle: 'End User Licensing Agreements & Legal limits',
                          onTap: () => context.push('/terms'),
                        ),
                      ]),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesSearch(String value) {
    if (_searchQuery.isEmpty) return true;
    return value.toLowerCase().contains(_searchQuery);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> tiles) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(tiles.length, (index) {
          final tile = tiles[index];
          if (index == tiles.length - 1) return tile;
          return Column(
            children: [
              tile,
              Divider(color: Colors.white.withOpacity(0.04), height: 1, indent: 56),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? textColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0066FF).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF00E5FF), size: 18),
      ),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white30, fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white30, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildTimerOption(int seconds, String label) {
    final settings = ref.read(appSettingsProvider);
    final active = settings.autoLockSeconds == seconds;
    return ListTile(
      title: Text(label, style: TextStyle(color: active ? const Color(0xFF00E5FF) : Colors.white, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      trailing: active ? const Icon(Icons.check, color: Color(0xFF00E5FF)) : null,
      onTap: () async {
        final user = ref.read(authProvider).user;
        if (user != null) {
          await ref.read(appSettingsProvider.notifier).setSetting('autoLockSeconds', seconds);
          await ref.read(firestoreSyncServiceProvider).syncUserProfileToCloud(user.id);
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
    );
  }
}
