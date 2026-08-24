import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../security/secure_storage_service.dart';

enum SmsBackgroundMonitorReadyState {
  ready,
  permissionRequired,
  disabled,
  error,
}

class SmsMonitorStatus {
  final PermissionStatus smsPermissionStatus;
  final PermissionStatus notificationPermissionStatus;
  final bool automaticDetectionActive;
  final SmsBackgroundMonitorReadyState backgroundMonitorReady;
  final DateTime? lastProcessedAt;
  final String? lastError;
  final bool receiverAvailable;

  SmsMonitorStatus({
    this.smsPermissionStatus = PermissionStatus.denied,
    this.notificationPermissionStatus = PermissionStatus.denied,
    this.automaticDetectionActive = false,
    this.backgroundMonitorReady = SmsBackgroundMonitorReadyState.permissionRequired,
    this.lastProcessedAt,
    this.lastError,
    this.receiverAvailable = false,
  });

  SmsMonitorStatus copyWith({
    PermissionStatus? smsPermissionStatus,
    PermissionStatus? notificationPermissionStatus,
    bool? automaticDetectionActive,
    SmsBackgroundMonitorReadyState? backgroundMonitorReady,
    DateTime? lastProcessedAt,
    String? lastError,
    bool? receiverAvailable,
  }) {
    return SmsMonitorStatus(
      smsPermissionStatus: smsPermissionStatus ?? this.smsPermissionStatus,
      notificationPermissionStatus: notificationPermissionStatus ?? this.notificationPermissionStatus,
      automaticDetectionActive: automaticDetectionActive ?? this.automaticDetectionActive,
      backgroundMonitorReady: backgroundMonitorReady ?? this.backgroundMonitorReady,
      lastProcessedAt: lastProcessedAt ?? this.lastProcessedAt,
      lastError: lastError ?? this.lastError,
      receiverAvailable: receiverAvailable ?? this.receiverAvailable,
    );
  }
}

class SmsMonitorStatusNotifier extends StateNotifier<SmsMonitorStatus> {
  final SecureStorageService _secureStorage;

  SmsMonitorStatusNotifier(this._secureStorage) : super(SmsMonitorStatus()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final lastProcessedStr = await _secureStorage.read('sms_stats_last_processed_time');
    final lastErr = await _secureStorage.read('sms_stats_last_error');
    DateTime? lastProcessed;
    if (lastProcessedStr != null) {
      lastProcessed = DateTime.tryParse(lastProcessedStr);
    }
    state = state.copyWith(
      lastProcessedAt: lastProcessed,
      lastError: lastErr,
    );
  }

  void updateStatus(SmsMonitorStatus status) {
    state = status;
  }
}

final StateNotifierProvider<SmsMonitorStatusNotifier, SmsMonitorStatus> smsMonitorStatusProvider =
    StateNotifierProvider<SmsMonitorStatusNotifier, SmsMonitorStatus>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return SmsMonitorStatusNotifier(secureStorage);
});
