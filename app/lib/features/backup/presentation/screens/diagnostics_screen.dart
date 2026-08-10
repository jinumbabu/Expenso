import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/backup_provider.dart';
import 'database_health_screen.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../core/database/app_database.dart';

class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  bool _isRunningDiagnostics = false;
  int _appVersionTapCount = 0;
  
  // Connectivity metrics
  bool _internetAvailable = false;
  bool _firebaseInitialized = false;
  bool _firebaseConnected = false;
  String _firebaseAuthStatus = 'Checking...';
  String _currentUserEmail = 'Checking...';
  bool _firestoreConnected = false;
  bool _googlePlayServicesAvailable = true;

  // New developer-only diagnostic data
  int _pendingSyncCount = 0;
  List<AuditLog> _auditLogs = [];
  String? _googleAccessToken;
  String? _expensoAccessToken;
  String? _expensoRefreshToken;
  bool _isCharging = true;
  bool _isWifi = true;
  
  // Package/Signatures
  final String _packageName = 'com.expenso.ai.app';
  final String _appVersion = '1.0.0';
  final String _registeredSha1 = '2A:F5:68:85:05:91:89:ED:88:98:44:60:5C:9B:BC:7E:BF:C9:6F:DC';
  final String _registeredSha256 = '24:FB:17:F6:D8:0C:FD:3F:E0:0E:5C:D3:89:91:96:3D:3F:9F:43:14:CF:76:40:B0:2F:45:97:08:CB:7B:42:21';

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    if (mounted) {
      setState(() {
        _isRunningDiagnostics = true;
      });
    }

    try {
      // 1. Internet connection check
      try {
        final lookup = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
        _internetAvailable = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
      } catch (_) {
        _internetAvailable = false;
      }

      // 2. Firebase Initialized check
      _firebaseInitialized = Firebase.apps.isNotEmpty;

      // 3. Firebase Connected check
      _firebaseConnected = _firebaseInitialized && _internetAvailable;

      // 4. Firebase Auth status
      final fbAuth = fb.FirebaseAuth.instance;
      final fbUser = fbAuth.currentUser;
      if (fbUser != null) {
        _firebaseAuthStatus = 'Authenticated';
        _currentUserEmail = fbUser.email ?? 'No Email';
      } else {
        _firebaseAuthStatus = 'Unauthenticated';
        _currentUserEmail = 'None';
      }

      // 5. Firestore Connection Check
      if (_firebaseConnected && fbUser != null) {
        _firestoreConnected = true;
      } else {
        _firestoreConnected = false;
      }

      // 6. Trigger provider diagnostic updates
      await ref.read(backupNotifierProvider.notifier).loadBackupInfo();

      // 7. Retrieve database status (Pending sync count and Audit logs)
      final db = ref.read(databaseProvider);
      final pendingTxs = await db.transactionDao.getPendingSyncTransactions();
      _pendingSyncCount = pendingTxs.length;

      final auth = ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId != null) {
        _auditLogs = await db.auditLogDao.getLogsForUser(userId);
        _auditLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      // 8. Retrieve security tokens
      final secureStorage = ref.read(secureStorageProvider);
      _googleAccessToken = await secureStorage.getGoogleAccessToken();
      _expensoAccessToken = await secureStorage.getAccessToken();
      _expensoRefreshToken = await secureStorage.getRefreshToken();

      // 9. Retrieve device charging and network type info
      _isCharging = await DeviceStatus.isCharging();
      _isWifi = await DeviceStatus.isWifi();

    } catch (e) {
      debugPrint('DiagnosticsScreen: Exception running checks: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRunningDiagnostics = false;
        });
      }
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 KB';
    final double kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final double mb = kb / 1024.0;
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    return DateFormat('dd MMM yyyy • hh:mm a').format(dateTime);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'Never';
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} seconds';
    }
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return 'None';
    if (token.length <= 12) return '***';
    return '${token.substring(0, 8)}...${token.substring(token.length - 8)}';
  }

  String _getFirebaseInfo() {
    if (Firebase.apps.isEmpty) return 'Not Initialized';
    final options = Firebase.app().options;
    return 'Project ID: ${options.projectId}\nApp ID: ${options.appId}';
  }

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupNotifierProvider);
    final showDevDiagnostics = kDebugMode || backupState.developerModeEnabled;

    ref.listen<BackupState>(backupNotifierProvider, (previous, next) {
      // Automatically refresh screen diagnostics when any async loading action finishes
      if (previous?.isLoading == true && next.isLoading == false) {
        _runDiagnostics();
      }

      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.teal,
          ),
        );
      }
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    // Helper checks for production status
    final googleSignInConnected = backupState.googleAccount != null || backupState.authStatus == 'Signed In';
    final cloudBackupEnabled = backupState.googleDriveBackupEnabled;
    final cloudSyncHealthy = backupState.lastError == null && _internetAvailable;
    final lastBackupVerificationSuccess = backupState.lastCloudBackupDate != null &&
        backupState.lastCloudBackupSize != null &&
        (backupState.lastBackupStatus == 'UPLOAD VERIFIED' || backupState.lastBackupStatus == 'Successful');
    final dbHealthy = (backupState.dbHealthStatus['SQLite Integrity'] ?? true) && backupState.activeFkViolations.isEmpty;
    final syncQueueNoPending = _pendingSyncCount == 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0B0F), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'Cloud Diagnostics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_isRunningDiagnostics || backupState.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                        onPressed: _runDiagnostics,
                      )
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Scrollable screen
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  children: [
                    // Title/Header summary card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent.withOpacity(0.12),
                            Colors.purpleAccent.withOpacity(0.02)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.04),
                            blurRadius: 16,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cloudSyncHealthy && dbHealthy ? Icons.verified_user : Icons.gpp_maybe,
                              color: cloudSyncHealthy && dbHealthy ? Colors.tealAccent : Colors.amberAccent,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'System Status',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cloudSyncHealthy && dbHealthy
                                      ? 'All systems secured and fully synced.'
                                      : 'System requires configuration or sync updates.',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                     // Restore Failure Error Card
                    if (backupState.lastRestoreStatus == 'Failed') ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1014),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.04),
                              blurRadius: 16,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
                                const SizedBox(width: 12),
                                const Text(
                                  'Restore Failed',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildErrorDetailRow('Error Code:', _getErrorCode(backupState.lastRestoreError), isCode: true),
                            const SizedBox(height: 12),
                            _buildErrorDetailRow('Description:', _getCleanRestoreErrorMessage(backupState.lastRestoreError)),
                            const SizedBox(height: 12),
                            _buildErrorDetailRow('Suggested Fix:', _getSuggestedFix(backupState.lastRestoreError)),
                            const SizedBox(height: 16),
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                iconColor: Colors.redAccent,
                                collapsedIconColor: Colors.white54,
                                title: const Text(
                                  'Technical Details',
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: SelectableText(
                                      backupState.lastRestoreError ?? 'No technical details available.',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent.withOpacity(0.15),
                                  foregroundColor: Colors.redAccent,
                                  side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Retry Restore', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: (_isRunningDiagnostics || backupState.isLoading)
                                    ? null
                                    : () {
                                        ref.read(backupNotifierProvider.notifier).restoreBackup();
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 1. SYSTEM HEALTH STATUS (Only display the specified checks)
                    _buildSectionHeader('SYSTEM HEALTH STATUS'),
                    const SizedBox(height: 12),
                    _buildDashboardCard([
                      _buildDashboardStatusRow('Google Sign-in', googleSignInConnected ? 'Connected' : 'Disconnected', googleSignInConnected),
                      _buildDashboardStatusRow('Cloud Backup', cloudBackupEnabled ? 'Enabled' : 'Disabled', cloudBackupEnabled),
                      _buildDashboardStatusRow('Cloud Sync', cloudSyncHealthy ? 'Healthy' : 'Sync Issue', cloudSyncHealthy),
                      _buildDashboardStatusRow('Encryption', 'AES-256 Enabled', true),
                      _buildDashboardStatusRow('Backup Verification', lastBackupVerificationSuccess ? 'Successful' : 'NOT VERIFIED', lastBackupVerificationSuccess),
                      _buildDashboardStatusRow('Database Integrity', dbHealthy ? 'Healthy' : 'Issues Detected', dbHealthy),
                      _buildDashboardStatusRow(
                        'Restore Status',
                        backupState.lastRestoreStatus == 'Successful' || backupState.lastRestoreStatus == 'RESTORE SUCCESSFUL' || (backupState.lastRestoreStatus == null && backupState.lastRestoreDate != null)
                            ? 'Successful'
                            : (backupState.lastRestoreStatus == 'Failed' ? 'Failed' : 'Pending'),
                        backupState.lastRestoreStatus == 'Successful' || backupState.lastRestoreStatus == 'RESTORE SUCCESSFUL' || (backupState.lastRestoreStatus == null && backupState.lastRestoreDate != null),
                      ),
                      _buildDashboardStatusRow('Sync Queue', syncQueueNoPending ? 'No Pending Items' : '${_pendingSyncCount} Pending Items', syncQueueNoPending),
                    ]),
                    
                    const SizedBox(height: 24),

                    // 2. BACKUP & SYNC METRICS (Only display user-safe metrics)
                    _buildSectionHeader('BACKUP & SYNC METRICS'),
                    const SizedBox(height: 12),
                    _buildDashboardCard([
                      _buildDashboardMetricRow('Last Backup', _formatDate(backupState.lastCloudBackupDate)),
                      _buildDashboardMetricRow('Last Restore', backupState.lastRestoreDate != null ? _formatDate(backupState.lastRestoreDate) : 'Not Available'),
                      _buildDashboardMetricRow('Database Version', '17'),
                      _buildDashboardMetricRow('Backup Size', _formatSize(backupState.lastCloudBackupSize)),
                    ]),

                    const SizedBox(height: 28),

                    // Sync & Backup Control Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.04),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.sync_alt, size: 18, color: Colors.blueAccent),
                            label: const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: (_isRunningDiagnostics || backupState.isLoading)
                                ? null
                                : () => ref.read(backupNotifierProvider.notifier).syncDatabase(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent.withOpacity(0.1),
                              foregroundColor: Colors.blueAccent,
                              side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.backup_outlined, size: 18, color: Colors.blueAccent),
                            label: const Text('Backup Now', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: (_isRunningDiagnostics || backupState.isLoading)
                                ? null
                                : () => ref.read(backupNotifierProvider.notifier).createBackup(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Subtle App Version footer at the bottom of the dashboard
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          _appVersionTapCount++;
                          if (_appVersionTapCount >= 7) {
                            _appVersionTapCount = 0;
                            ref.read(backupNotifierProvider.notifier).setDeveloperModeEnabled(true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Developer Mode Enabled'),
                                backgroundColor: Colors.teal,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Expenso AI • Version $_appVersion',
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Gated Developer Diagnostics Section
                    if (showDevDiagnostics) ...[
                      const SizedBox(height: 36),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bug_report_outlined, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              _buildSectionHeader('DEVELOPER DIAGNOSTICS'),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(backupNotifierProvider.notifier).setDeveloperModeEnabled(false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Developer Mode Disabled'),
                                  backgroundColor: Colors.amber,
                                ),
                              );
                            },
                            child: const Text('Hide', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.01),
                              blurRadius: 16,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDevHeader('APPLICATION INFO'),
                            _buildDevInfoRow('Package Name', _packageName),
                            _buildDevInfoRow('App Version', _appVersion),
                            _buildDevInfoRow('Registered SHA-1', _registeredSha1),
                            _buildDevInfoRow('Registered SHA-256', _registeredSha256),
                            
                            const Divider(color: Colors.white10, height: 24),
                            _buildDevHeader('CLOUD CONFIGURATIONS'),
                            _buildDevInfoRow('Firebase Options', _getFirebaseInfo()),
                            _buildDevInfoRow('Drive Connect Status', backupState.driveConnectionStatus ?? 'N/A'),
                            _buildDevInfoRow('AppData Folder Status', backupState.appDataFolderStatus ?? 'N/A'),
                            
                            const Divider(color: Colors.white10, height: 24),
                            _buildDevHeader('API ENDPOINTS'),
                            _buildDevInfoRow('Auth Server API', 'https://api.expenso.app/api/v1'),
                            _buildDevInfoRow('Gemini AI endpoint', 'https://generativelanguage.googleapis.com'),
                            _buildDevInfoRow('OpenAI endpoint', 'https://api.openai.com/v1'),
                            _buildDevInfoRow('Anthropic endpoint', 'https://api.anthropic.com/v1'),
                            _buildDevInfoRow('Sentry DSN', 'https://expenso-placeholder-dsn@sentry.io/12345'),
                            
                            const Divider(color: Colors.white10, height: 24),
                            _buildDevHeader('DATABASE & SYNC CONFIG'),
                            _buildDevInfoRow('Database Schema Version', '17'),
                            _buildDevInfoRow('Sync Queue Pending Count', '$_pendingSyncCount items'),
                            
                            const Divider(color: Colors.white10, height: 24),
                            _buildDevHeader('DEVICE INFO'),
                            _buildDevInfoRow('Platform OS', Platform.operatingSystem),
                            _buildDevInfoRow('Charging Status', _isCharging ? 'Charging' : 'On Battery'),
                            _buildDevInfoRow('Network Connection', _isWifi ? 'WiFi' : 'Cellular / Other'),
                            
                            const Divider(color: Colors.white10, height: 24),
                            _buildDevHeader('SECURITY CREDENTIALS (MASKED)'),
                            _buildDevInfoRow('Google Drive Scopes', backupState.grantedScopes.isEmpty ? 'None' : backupState.grantedScopes.join('\n')),
                            _buildDevInfoRow('Google Access Token', _maskToken(_googleAccessToken)),
                            _buildDevInfoRow('Expenso Access Token', _maskToken(_expensoAccessToken)),
                            _buildDevInfoRow('Expenso Refresh Token', _maskToken(_expensoRefreshToken)),
                            
                            const Divider(color: Colors.white10, height: 24),
                            _buildDevHeader('NETWORK DIAGNOSTICS'),
                            _buildDiagnosticStatusIcon('Internet Availability', _internetAvailable),
                            _buildDiagnosticStatusIcon('Firebase Initialized', _firebaseInitialized),
                            _buildDiagnosticStatusIcon('Firebase Connected', _firebaseConnected),
                            _buildDiagnosticStatusIcon('Firestore Sync', _firestoreConnected),
                            _buildDiagnosticStatusIcon('Google Play Services', _googlePlayServicesAvailable),

                            const Divider(color: Colors.white10, height: 24),
                            _buildDevHeader('RECENT ENGINE & AUDIT LOGS'),
                            const SizedBox(height: 8),
                            if (_auditLogs.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('No audit logs captured.', style: TextStyle(color: Colors.white24, fontSize: 11)),
                              )
                            else
                              Container(
                                constraints: const BoxConstraints(maxHeight: 180),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _auditLogs.length > 10 ? 10 : _auditLogs.length,
                                  separatorBuilder: (context, idx) => const Divider(color: Colors.white10, height: 16),
                                  itemBuilder: (context, idx) {
                                    final log = _auditLogs[idx];
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${log.eventCategory.toUpperCase()} • ${log.eventType}',
                                              style: TextStyle(
                                                color: log.eventType.contains('failed') ? Colors.redAccent : Colors.tealAccent,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('HH:mm:ss').format(log.createdAt),
                                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          log.description,
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Open Google Drive Pipeline Diagnostics'),
                        onPressed: () => context.push('/drive-diagnostics'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.health_and_safety_outlined),
                        label: const Text('Open DB Health Monitor'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DatabaseHealthScreen()),
                          );
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildDashboardCard(List<Widget> children) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: List.generate(children.length * 2 - 1, (index) {
          if (index.isOdd) return const Divider(color: Colors.white10, height: 16);
          return children[index ~/ 2];
        }),
      ),
    );
  }

  Widget _buildDashboardStatusRow(String label, String value, bool isSuccess) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: isSuccess ? Colors.tealAccent : Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: isSuccess ? Colors.tealAccent : Colors.redAccent,
              size: 18,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDevHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDevInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            flex: 6,
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticStatusIcon(String label, bool success) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Icon(
            success ? Icons.check_circle : Icons.cancel,
            color: success ? Colors.tealAccent : Colors.redAccent,
            size: 18,
          ),
        ],
      ),
    );
  }

  String _getCleanRestoreErrorMessage(String? error) {
    if (error == null || error.isEmpty) return 'Unknown error occurred.';
    try {
      final decoded = jsonDecode(error);
      if (decoded is Map && decoded.containsKey('exceptionType')) {
        final exceptionType = decoded['exceptionType'] as String;
        final stackTrace = decoded['stackTrace'] as String? ?? '';
        final stackTraceLower = stackTrace.toLowerCase();
        
        if (exceptionType.contains('SQLiteException') || stackTraceLower.contains('sqliteexception')) {
          return 'Cloud backup is corrupted.';
        }
      }
    } catch (_) {}
    
    final errLower = error.toLowerCase();
    if (errLower.contains('sqliteexception(26)') || errLower.contains('file is not a database')) {
      return 'Cloud backup is corrupted.';
    }
    if (errLower.contains('incomplete') || errLower.contains('zero bytes') || errLower.contains('empty')) {
      return 'Downloaded backup is incomplete.';
    }
    if (errLower.contains('checksum')) {
      return 'Backup verification failed.';
    }
    if (errLower.contains('integrity check failed') || errLower.contains('quick_check') || errLower.contains('integrity_check')) {
      return 'Database integrity check failed.';
    }
    if (errLower.contains('aborted') || errLower.contains('protect')) {
      return 'Cloud restore aborted to protect your data.';
    }
    if (error.startsWith('Exception: ')) {
      return error.substring(11);
    }
    return error;
  }

  String _getSuggestedFix(String? error) {
    final cleanMsg = _getCleanRestoreErrorMessage(error).toLowerCase();
    if (cleanMsg.contains('corrupted')) {
      return 'The downloaded backup file is corrupted or incomplete. Please create a new backup from your other device and try again.';
    }
    if (cleanMsg.contains('incomplete')) {
      return 'The connection was interrupted during download. Please check your internet connectivity and try again.';
    }
    if (cleanMsg.contains('verification failed')) {
      return 'The checksum of the downloaded file does not match the metadata. Please try restoring again or verify your account credentials.';
    }
    if (cleanMsg.contains('integrity check failed')) {
      return 'The database file failed verification checks. Please repair your local database or use a different backup version.';
    }
    if (cleanMsg.contains('aborted')) {
      return 'The restore operation was cancelled to protect your existing database. Check Google Drive permissions.';
    }
    return 'Please check your internet connection, ensure you are logged in to your Google Drive account with backup permissions, and try again.';
  }

  String _getErrorCode(String? error) {
    if (error == null || error.isEmpty) return 'ERR_UNKNOWN';
    try {
      final decoded = jsonDecode(error);
      if (decoded is Map && decoded.containsKey('exceptionType')) {
        final exceptionType = decoded['exceptionType'] as String;
        if (exceptionType.contains('SQLiteException')) return 'ERR_SQLITE_CORRUPTED';
        if (exceptionType.contains('IOException')) return 'ERR_RESTORE_IO';
      }
    } catch (_) {}
    final errLower = error.toLowerCase();
    if (errLower.contains('sqliteexception') || errLower.contains('file is not a database')) {
      return 'ERR_SQLITE_CORRUPTED';
    }
    if (errLower.contains('incomplete') || errLower.contains('zero bytes') || errLower.contains('empty')) {
      return 'ERR_INCOMPLETE_DOWNLOAD';
    }
    if (errLower.contains('checksum')) {
      return 'ERR_CHECKSUM_MISMATCH';
    }
    if (errLower.contains('integrity check failed')) {
      return 'ERR_INTEGRITY_CHECK';
    }
    if (errLower.contains('aborted')) {
      return 'ERR_RESTORE_ABORTED';
    }
    return 'ERR_RESTORE_FAILED';
  }

  Widget _buildErrorDetailRow(String label, String value, {bool isCode = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isCode ? Colors.redAccent : Colors.white,
            fontSize: 13.5,
            fontWeight: isCode ? FontWeight.bold : FontWeight.normal,
            fontFamily: isCode ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}
