import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../security/audit_logger.dart';

class SmsPermissionStatusModel {
  final PermissionStatus smsStatus;
  final PermissionStatus notificationStatus;
  final bool isInboxAccessible;

  SmsPermissionStatusModel({
    required this.smsStatus,
    required this.notificationStatus,
    required this.isInboxAccessible,
  });

  bool get isGranted => smsStatus.isGranted;
}

class SmsPermissionManager {
  final AuditLogger? _auditLogger;

  SmsPermissionManager([this._auditLogger]);

  /// Centralized check of the actual Android permission state.
  /// Never caches permission state in Flutter memory.
  Future<SmsPermissionStatusModel> checkActualPermissions() async {
    PermissionStatus smsStatus = PermissionStatus.denied;
    PermissionStatus notifStatus = PermissionStatus.denied;

    try {
      smsStatus = await Permission.sms.status;
      notifStatus = await Permission.notification.status;
    } catch (e) {
      debugPrint("SmsPermissionManager: Error checking OS permissions: $e");
    }

    bool inboxOk = false;
    if (smsStatus.isGranted) {
      inboxOk = true; // Handled at native level
    }

    return SmsPermissionStatusModel(
      smsStatus: smsStatus,
      notificationStatus: notifStatus,
      isInboxAccessible: inboxOk,
    );
  }

  /// Central request handler for SMS permissions.
  /// If the permission is permanently denied, returns permanentlyDenied so that 
  /// UI or notifier can prompt user to open Settings.
  Future<PermissionStatus> requestSmsPermission(String? userId) async {
    if (_auditLogger != null) {
      await _auditLogger!.logEvent(
        userId: userId,
        eventType: 'sms_permission_request_attempt',
        eventCategory: 'security',
        description: 'Attempting to request SMS runtime permission via Centralized Manager.',
      );
    }

    PermissionStatus status = PermissionStatus.denied;
    try {
      status = await Permission.sms.request();
    } catch (e) {
      debugPrint("SmsPermissionManager: Error requesting SMS permission: $e");
    }

    if (_auditLogger != null) {
      await _auditLogger!.logEvent(
        userId: userId,
        eventType: 'sms_permission_updated',
        eventCategory: 'security',
        description: 'SMS permission request completed. Status: $status',
        metadata: {'status': status.toString()},
      );
    }

    return status;
  }

  /// Request notifications permission
  Future<PermissionStatus> requestNotificationPermission(String? userId) async {
    if (_auditLogger != null) {
      await _auditLogger!.logEvent(
        userId: userId,
        eventType: 'notification_permission_request_attempt',
        eventCategory: 'security',
        description: 'Attempting to request notification runtime permission via Centralized Manager.',
      );
    }

    PermissionStatus status = PermissionStatus.denied;
    try {
      status = await Permission.notification.request();
    } catch (e) {
      debugPrint("SmsPermissionManager: Error requesting notification permission: $e");
    }

    if (_auditLogger != null) {
      await _auditLogger!.logEvent(
        userId: userId,
        eventType: 'notification_permission_updated',
        eventCategory: 'security',
        description: 'Notification permission request completed. Status: $status',
        metadata: {'status': status.toString()},
      );
    }

    return status;
  }

  /// Direct link helper to open Android App Settings if permission is permanently denied.
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
