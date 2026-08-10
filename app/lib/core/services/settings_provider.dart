import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/secure_storage_service.dart';
import '../security/app_lock_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AppSettingsState {
  final bool hideNetWorth;
  final bool hideAccountBalances;
  final bool hideTransactionAmounts;
  final bool hideAnalyticsAmounts;
  final bool hideDashboard;
  final bool hideAccountDetails;
  final bool hideCards;
  final bool pinEnabled;
  final int pinLength;
  final bool biometricEnabled;
  final bool screenSecurityEnabled;
  final int autoLockSeconds;
  final String aiPrivacyMode;
  final bool googleDriveBackupEnabled;
  final bool backupWifiOnly;
  final bool backupChargingOnly;
  final String backupSchedule;
  final bool privacyModeEnabled;

  AppSettingsState({
    this.hideNetWorth = false,
    this.hideAccountBalances = false,
    this.hideTransactionAmounts = false,
    this.hideAnalyticsAmounts = false,
    this.hideDashboard = false,
    this.hideAccountDetails = false,
    this.hideCards = false,
    this.pinEnabled = false,
    this.pinLength = 4,
    this.biometricEnabled = false,
    this.screenSecurityEnabled = false,
    this.autoLockSeconds = -1,
    this.aiPrivacyMode = 'hybrid',
    this.googleDriveBackupEnabled = false,
    this.backupWifiOnly = false,
    this.backupChargingOnly = false,
    this.backupSchedule = 'daily',
    this.privacyModeEnabled = false,
  });

  AppSettingsState copyWith({
    bool? hideNetWorth,
    bool? hideAccountBalances,
    bool? hideTransactionAmounts,
    bool? hideAnalyticsAmounts,
    bool? hideDashboard,
    bool? hideAccountDetails,
    bool? hideCards,
    bool? pinEnabled,
    int? pinLength,
    bool? biometricEnabled,
    bool? screenSecurityEnabled,
    int? autoLockSeconds,
    String? aiPrivacyMode,
    bool? googleDriveBackupEnabled,
    bool? backupWifiOnly,
    bool? backupChargingOnly,
    String? backupSchedule,
    bool? privacyModeEnabled,
  }) {
    return AppSettingsState(
      hideNetWorth: hideNetWorth ?? this.hideNetWorth,
      hideAccountBalances: hideAccountBalances ?? this.hideAccountBalances,
      hideTransactionAmounts: hideTransactionAmounts ?? this.hideTransactionAmounts,
      hideAnalyticsAmounts: hideAnalyticsAmounts ?? this.hideAnalyticsAmounts,
      hideDashboard: hideDashboard ?? this.hideDashboard,
      hideAccountDetails: hideAccountDetails ?? this.hideAccountDetails,
      hideCards: hideCards ?? this.hideCards,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pinLength: pinLength ?? this.pinLength,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      screenSecurityEnabled: screenSecurityEnabled ?? this.screenSecurityEnabled,
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      aiPrivacyMode: aiPrivacyMode ?? this.aiPrivacyMode,
      googleDriveBackupEnabled: googleDriveBackupEnabled ?? this.googleDriveBackupEnabled,
      backupWifiOnly: backupWifiOnly ?? this.backupWifiOnly,
      backupChargingOnly: backupChargingOnly ?? this.backupChargingOnly,
      backupSchedule: backupSchedule ?? this.backupSchedule,
      privacyModeEnabled: privacyModeEnabled ?? this.privacyModeEnabled,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  final SecureStorageService _secureStorage;
  final AppLockService _appLock;
  final String? _userId;

  AppSettingsNotifier(this._secureStorage, this._appLock, this._userId)
      : super(AppSettingsState()) {
    _load();
  }

  Future<void> _load() async {
    if (_userId == null) return;
    try {
      final nw = await _secureStorage.read('hide_net_worth_$_userId') == 'true';
      final ab = await _secureStorage.read('hide_account_balances_$_userId') == 'true';
      final ta = await _secureStorage.read('hide_transaction_amounts_$_userId') == 'true';
      final aa = await _secureStorage.read('hide_analytics_amounts_$_userId') == 'true';
      final db = await _secureStorage.read('hide_dashboard_$_userId') == 'true';
      final ad = await _secureStorage.read('hide_account_details_$_userId') == 'true';
      final hc = await _secureStorage.read('hide_cards_$_userId') == 'true';

      final pinSet = await _appLock.isPinSet(_userId!);
      final pinLen = await _appLock.getPinLength(_userId!);
      final bioSet = await _appLock.isBiometricEnabled(_userId!);
      final screenSec = await _appLock.isScreenSecurityEnabled(_userId!);
      final autoLock = await _appLock.getAutoLockTimer(_userId!);

      final aiMode = await _secureStorage.read('ai_privacy_mode') ?? 'hybrid';
      
      final gdBackup = await _secureStorage.read('google_drive_backup_enabled_$_userId') == 'true';
      final wifiOnly = await _secureStorage.read('backup_wifi_only_$_userId') == 'true';
      final chargingOnly = await _secureStorage.read('backup_charging_only_$_userId') == 'true';
      final schedule = await _secureStorage.read('backup_schedule_$_userId') ?? 'daily';

      final privMode = await _secureStorage.getPrivacyMode() == 'true';

      state = AppSettingsState(
        hideNetWorth: nw,
        hideAccountBalances: ab,
        hideTransactionAmounts: ta,
        hideAnalyticsAmounts: aa,
        hideDashboard: db,
        hideAccountDetails: ad,
        hideCards: hc,
        pinEnabled: pinSet,
        pinLength: pinLen,
        biometricEnabled: bioSet,
        screenSecurityEnabled: screenSec,
        autoLockSeconds: autoLock,
        aiPrivacyMode: aiMode,
        googleDriveBackupEnabled: gdBackup,
        backupWifiOnly: wifiOnly,
        backupChargingOnly: chargingOnly,
        backupSchedule: schedule,
        privacyModeEnabled: privMode,
      );

      // Apply screen security natively on settings load
      if (screenSec) {
        await _appLock.applyScreenSecurity(_userId!);
      }
    } catch (_) {}
  }

  Future<void> setSetting(String key, dynamic value) async {
    if (_userId == null) return;
    
    // 1. Update in-memory state instantly
    switch (key) {
      case 'hideNetWorth':
        state = state.copyWith(hideNetWorth: value as bool);
        break;
      case 'hideAccountBalances':
        state = state.copyWith(hideAccountBalances: value as bool);
        break;
      case 'hideTransactionAmounts':
        state = state.copyWith(hideTransactionAmounts: value as bool);
        break;
      case 'hideAnalyticsAmounts':
        state = state.copyWith(hideAnalyticsAmounts: value as bool);
        break;
      case 'hideDashboard':
        state = state.copyWith(hideDashboard: value as bool);
        break;
      case 'hideAccountDetails':
        state = state.copyWith(hideAccountDetails: value as bool);
        break;
      case 'hideCards':
        state = state.copyWith(hideCards: value as bool);
        break;
      case 'pinEnabled':
        state = state.copyWith(pinEnabled: value as bool);
        break;
      case 'pinLength':
        state = state.copyWith(pinLength: value as int);
        break;
      case 'biometricEnabled':
        state = state.copyWith(biometricEnabled: value as bool);
        break;
      case 'screenSecurityEnabled':
        state = state.copyWith(screenSecurityEnabled: value as bool);
        break;
      case 'autoLockSeconds':
        state = state.copyWith(autoLockSeconds: value as int);
        break;
      case 'aiPrivacyMode':
        state = state.copyWith(aiPrivacyMode: value as String);
        break;
      case 'googleDriveBackupEnabled':
        state = state.copyWith(googleDriveBackupEnabled: value as bool);
        break;
      case 'backupWifiOnly':
        state = state.copyWith(backupWifiOnly: value as bool);
        break;
      case 'backupChargingOnly':
        state = state.copyWith(backupChargingOnly: value as bool);
        break;
      case 'backupSchedule':
        state = state.copyWith(backupSchedule: value as String);
        break;
      case 'privacyModeEnabled':
        state = state.copyWith(privacyModeEnabled: value as bool);
        break;
    }

    // 2. Persist to storage asynchronously in the background
    _persistSetting(key, value);
  }

  Future<void> _persistSetting(String key, dynamic value) async {
    if (_userId == null) return;
    try {
      switch (key) {
        case 'hideNetWorth':
          await _secureStorage.write('hide_net_worth_$_userId', value.toString());
          break;
        case 'hideAccountBalances':
          await _secureStorage.write('hide_account_balances_$_userId', value.toString());
          break;
        case 'hideTransactionAmounts':
          await _secureStorage.write('hide_transaction_amounts_$_userId', value.toString());
          break;
        case 'hideAnalyticsAmounts':
          await _secureStorage.write('hide_analytics_amounts_$_userId', value.toString());
          break;
        case 'hideDashboard':
          await _secureStorage.write('hide_dashboard_$_userId', value.toString());
          break;
        case 'hideAccountDetails':
          await _secureStorage.write('hide_account_details_$_userId', value.toString());
          break;
        case 'hideCards':
          await _secureStorage.write('hide_cards_$_userId', value.toString());
          break;
        case 'biometricEnabled':
          await _appLock.setBiometricEnabled(_userId!, value as bool);
          break;
        case 'screenSecurityEnabled':
          await _appLock.setScreenSecurityEnabled(_userId!, value as bool);
          break;
        case 'autoLockSeconds':
          await _appLock.saveAutoLockTimer(_userId!, value as int);
          break;
        case 'aiPrivacyMode':
          await _secureStorage.write('ai_privacy_mode', value as String);
          break;
        case 'googleDriveBackupEnabled':
          await _secureStorage.write('google_drive_backup_enabled_$_userId', value.toString());
          break;
        case 'backupWifiOnly':
          await _secureStorage.write('backup_wifi_only_$_userId', value.toString());
          break;
        case 'backupChargingOnly':
          await _secureStorage.write('backup_charging_only_$_userId', value.toString());
          break;
        case 'backupSchedule':
          await _secureStorage.write('backup_schedule_$_userId', value as String);
          break;
        case 'privacyModeEnabled':
          await _secureStorage.savePrivacyMode(value.toString());
          break;
      }
    } catch (_) {}
  }

  Future<void> setHideAll(bool hide) async {
    if (_userId == null) return;
    state = state.copyWith(
      hideNetWorth: hide,
      hideAccountBalances: hide,
      hideTransactionAmounts: hide,
      hideAnalyticsAmounts: hide,
      hideDashboard: hide,
      hideAccountDetails: hide,
      hideCards: hide,
    );
    await _secureStorage.write('hide_net_worth_$_userId', hide.toString());
    await _secureStorage.write('hide_account_balances_$_userId', hide.toString());
    await _secureStorage.write('hide_transaction_amounts_$_userId', hide.toString());
    await _secureStorage.write('hide_analytics_amounts_$_userId', hide.toString());
    await _secureStorage.write('hide_dashboard_$_userId', hide.toString());
    await _secureStorage.write('hide_account_details_$_userId', hide.toString());
    await _secureStorage.write('hide_cards_$_userId', hide.toString());
  }

  Future<void> refreshLockState() async {
    if (_userId == null) return;
    final pinSet = await _appLock.isPinSet(_userId!);
    final pinLen = await _appLock.getPinLength(_userId!);
    state = state.copyWith(pinEnabled: pinSet, pinLength: pinLen);
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  final secureStorage = ref.watch(secureStorageProvider);
  final appLock = ref.watch(appLockServiceProvider);
  return AppSettingsNotifier(secureStorage, appLock, userId);
});
