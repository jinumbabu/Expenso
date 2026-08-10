import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/backup_provider.dart';
import '../../../../shared/widgets/glass_card.dart';

class GoogleDriveDiagnosticsScreen extends ConsumerStatefulWidget {
  const GoogleDriveDiagnosticsScreen({super.key});

  @override
  ConsumerState<GoogleDriveDiagnosticsScreen> createState() => _GoogleDriveDiagnosticsScreenState();
}

class _DatabaseDiagnosticStep {
  final String title;
  final String status; // 'PENDING', 'PASS', 'FAIL'
  final String details;
  final IconData icon;

  _DatabaseDiagnosticStep({
    required this.title,
    required this.status,
    required this.details,
    required this.icon,
  });
}

class _GoogleDriveDiagnosticsScreenState extends ConsumerState<GoogleDriveDiagnosticsScreen> {
  @override
  void initState() {
    super.initState();
    // Run diagnostics check on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupNotifierProvider.notifier).runGoogleDriveDiagnostics();
    });
  }

  void _copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  List<_DatabaseDiagnosticStep> _getSteps(GoogleDriveDiagnosticReport report) {
    return [
      _DatabaseDiagnosticStep(
        title: 'Step 1: Google Sign-In',
        status: report.step1SignIn,
        details: report.step1Details,
        icon: Icons.login_outlined,
      ),
      _DatabaseDiagnosticStep(
        title: 'Step 2: Authenticated HTTP Client',
        status: report.step2Client,
        details: report.step2Details,
        icon: Icons.http_outlined,
      ),
      _DatabaseDiagnosticStep(
        title: 'Step 3: Drive API Client',
        status: report.step3Api,
        details: report.step3Details,
        icon: Icons.api_outlined,
      ),
      _DatabaseDiagnosticStep(
        title: 'Step 4: AppData Folder Verification',
        status: report.step4AppData,
        details: report.step4Details,
        icon: Icons.folder_shared_outlined,
      ),
      _DatabaseDiagnosticStep(
        title: 'Step 5: Create Temporary Test File',
        status: report.step5Upload,
        details: report.step5Details,
        icon: Icons.upload_file_outlined,
      ),
      _DatabaseDiagnosticStep(
        title: 'Step 6: Upload Verification (Get)',
        status: report.step6Get,
        details: report.step6Get == 'PENDING' ? '' : report.step6Details,
        icon: Icons.fact_check_outlined,
      ),
      _DatabaseDiagnosticStep(
        title: 'Step 7: Download & Checksum Verification',
        status: report.step7Download,
        details: report.step7Download == 'PENDING' ? '' : report.step7Details,
        icon: Icons.download_done_outlined,
      ),
      _DatabaseDiagnosticStep(
        title: 'Step 8: Delete Temporary Test File',
        status: report.step8Delete,
        details: report.step8Delete == 'PENDING' ? '' : report.step8Details,
        icon: Icons.delete_sweep_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(backupNotifierProvider);
    final googleSignIn = ref.watch(googleSignInProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final report = state.googleDriveDiagnosticReport ?? GoogleDriveDiagnosticReport();
    final steps = _getSteps(report);

    // Calculate pipeline summary status
    bool hasFailure = steps.any((s) => s.status == 'FAIL');
    bool allPass = steps.every((s) => s.status == 'PASS');

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Drive Diagnostics Pipeline'),
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
          if (!state.isDiagnosticsRunning)
            IconButton(
              icon: const Icon(Icons.play_circle_fill_outlined, color: Colors.blueAccent),
              onPressed: () {
                ref.read(backupNotifierProvider.notifier).runGoogleDriveDiagnostics();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Starting Google Drive diagnostics check...')),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient soft color glows
          Positioned(
            top: -80,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: allPass
                    ? Colors.green.withOpacity(0.12)
                    : (hasFailure ? Colors.red.withOpacity(0.12) : Colors.blue.withOpacity(0.12)),
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
                color: Colors.purple.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // State summary card
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: state.isDiagnosticsRunning
                                  ? Colors.blue.withOpacity(0.2)
                                  : (allPass
                                      ? Colors.green.withOpacity(0.2)
                                      : (hasFailure
                                          ? Colors.redAccent.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.2))),
                              shape: BoxShape.circle,
                            ),
                            child: state.isDiagnosticsRunning
                                ? const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                    ),
                                  )
                                : Icon(
                                    allPass
                                        ? Icons.verified
                                        : (hasFailure ? Icons.error : Icons.help_outline),
                                    color: allPass
                                        ? Colors.green
                                        : (hasFailure ? Colors.redAccent : Colors.grey),
                                    size: 32,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.isDiagnosticsRunning
                                      ? 'Running Pipeline Checks...'
                                      : (allPass
                                          ? 'Pipeline Verification: PASS'
                                          : (hasFailure
                                              ? 'Pipeline Verification: FAIL'
                                              : 'Pipeline Status: IDLE')),
                                  style: TextStyle(
                                    color: state.isDiagnosticsRunning
                                        ? Colors.blueAccent
                                        : (allPass
                                            ? Colors.green
                                            : (hasFailure ? Colors.redAccent : Colors.white70)),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state.isDiagnosticsRunning
                                      ? 'Testing active Google Sign-In and hidden folder read/write tasks...'
                                      : (allPass
                                          ? 'All 8 stages of the Drive Backup API pipeline checked and verified.'
                                          : (hasFailure
                                              ? 'A failure occurred in the backup execution sequence. See details below.'
                                              : 'Run diagnostics to verify connection to Google Drive API.')),
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

                  // Google Account Info Card
                  const Text(
                    'Google Authorization Metadata',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow('Firebase User UID', firebaseUser?.uid ?? 'Not Logged In'),
                        const Divider(color: Colors.white10, height: 16),
                        _buildMetaRow('GoogleSignIn Email', googleSignIn.currentUser?.email ?? 'Not Logged In'),
                        const Divider(color: Colors.white10, height: 16),
                        _buildMetaRow('GoogleSignIn Name', googleSignIn.currentUser?.displayName ?? 'Not Logged In'),
                        const Divider(color: Colors.white10, height: 16),
                        _buildMetaRow('OAuth Scopes Granted', googleSignIn.currentUser == null ? 'None' : googleSignIn.scopes.join('\n')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pipeline Step list
                  const Text(
                    'Backup Pipeline Operations',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      Color statusBgColor = Colors.grey.withOpacity(0.1);
                      Color statusBorderColor = Colors.white10;
                      Color statusTextColor = Colors.white38;

                      if (step.status == 'PASS') {
                        statusBgColor = Colors.green.withOpacity(0.15);
                        statusBorderColor = Colors.green.withOpacity(0.4);
                        statusTextColor = Colors.green;
                      } else if (step.status == 'FAIL') {
                        statusBgColor = Colors.red.withOpacity(0.15);
                        statusBorderColor = Colors.red.withOpacity(0.4);
                        statusTextColor = Colors.redAccent;
                      } else if (step.status == 'PENDING') {
                        statusBgColor = Colors.blue.withOpacity(0.08);
                        statusBorderColor = Colors.blue.withOpacity(0.2);
                        statusTextColor = Colors.blueAccent;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: ExpansionTile(
                            leading: Icon(
                              step.icon,
                              color: step.status == 'PASS'
                                  ? Colors.green
                                  : (step.status == 'FAIL' ? Colors.redAccent : Colors.blueAccent),
                            ),
                            title: Text(
                              step.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusBorderColor),
                              ),
                              child: Text(
                                step.status,
                                style: TextStyle(
                                  color: statusTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16.0),
                                color: Colors.black12,
                                child: Text(
                                  step.details.isEmpty ? 'No diagnostic details logged.' : step.details,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12.5,
                                    fontFamily: 'monospace',
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                   // Diagnostics failure details block (if any step failed)
                  if (hasFailure) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Pipeline Failure Diagnostics',
                      style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildErrorDetailRow(
                            'Error Code:',
                            _getDriveErrorCode(report.lastException, report.lastHttpStatus),
                            isCode: true,
                          ),
                          if (report.lastHttpStatus != null) ...[
                            const SizedBox(height: 12),
                            _buildErrorDetailRow('HTTP Status Code:', '${report.lastHttpStatus}'),
                          ],
                          const SizedBox(height: 12),
                          _buildErrorDetailRow(
                            'Description:',
                            _getDriveCleanErrorMessage(report.lastException, report.lastHttpStatus),
                          ),
                          const SizedBox(height: 12),
                          _buildErrorDetailRow(
                            'Suggested Fix:',
                            _getDriveSuggestedFix(report.lastException, report.lastHttpStatus),
                          ),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'API Exception:',
                                            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy, size: 14, color: Colors.white54),
                                            onPressed: () => _copyToClipboard('API Exception', report.lastException ?? 'None'),
                                          ),
                                        ],
                                      ),
                                      SelectableText(
                                        report.lastException ?? 'No exception caught.',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      if (report.lastStackTrace != null) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Stack Trace:',
                                              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.copy, size: 14, color: Colors.white54),
                                              onPressed: () => _copyToClipboard('Stack Trace', report.lastStackTrace!),
                                            ),
                                          ],
                                        ),
                                        SelectableText(
                                          report.lastStackTrace!,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  if (!state.isDiagnosticsRunning)
                    ElevatedButton(
                      onPressed: () {
                        ref.read(backupNotifierProvider.notifier).runGoogleDriveDiagnostics();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Re-run Diagnostic Pipeline', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _getDriveErrorCode(String? error, int? httpStatus) {
    if (httpStatus == 401 || httpStatus == 403) return 'ERR_DRIVE_AUTH_FAILED';
    if (httpStatus == 404) return 'ERR_DRIVE_FILE_NOT_FOUND';
    if (error == null || error.isEmpty) return 'ERR_UNKNOWN';
    final errLower = error.toLowerCase();
    if (errLower.contains('timeout') || errLower.contains('socketexception') || errLower.contains('host')) {
      return 'ERR_DRIVE_NETWORK_TIMEOUT';
    }
    if (errLower.contains('permission') || errLower.contains('denied') || errLower.contains('scope')) {
      return 'ERR_DRIVE_PERMISSION_DENIED';
    }
    return 'ERR_DRIVE_PIPELINE_FAILED';
  }

  String _getDriveCleanErrorMessage(String? error, int? httpStatus) {
    if (httpStatus == 401 || httpStatus == 403) {
      return 'Google Drive authentication failed or expired.';
    }
    if (httpStatus == 404) {
      return 'Backup directory or file not found on Google Drive.';
    }
    if (error == null || error.isEmpty) return 'An unexpected error occurred in the Google Drive pipeline.';
    final errLower = error.toLowerCase();
    if (errLower.contains('timeout') || errLower.contains('socketexception') || errLower.contains('host')) {
      return 'Network connection timed out.';
    }
    if (errLower.contains('permission') || errLower.contains('denied') || errLower.contains('scope')) {
      return 'Permission denied to access the appDataFolder space.';
    }
    if (error.startsWith('Exception: ')) {
      return error.substring(11);
    }
    return error;
  }

  String _getDriveSuggestedFix(String? error, int? httpStatus) {
    if (httpStatus == 401 || httpStatus == 403) {
      return 'Please try signing out of your Google account, sign back in, and ensure you grant full AppData access permissions.';
    }
    if (httpStatus == 404) {
      return 'The hidden Expenso folder on Google Drive could not be resolved. Please try running a manual backup to re-create it.';
    }
    final cleanMsg = _getDriveCleanErrorMessage(error, httpStatus).toLowerCase();
    if (cleanMsg.contains('timeout') || cleanMsg.contains('network')) {
      return 'Please check your Wi-Fi or cellular network connection and verify if google.com is accessible.';
    }
    if (cleanMsg.contains('permission')) {
      return 'Expenso needs access to Google Drive AppData folder to store backups. Re-authenticate and check the permission checkbox.';
    }
    return 'Please sign out of Google Drive, restart the app, and run diagnostics again. Contact support if the issue persists.';
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
