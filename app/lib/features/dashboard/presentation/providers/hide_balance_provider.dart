import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/settings_provider.dart';

class HideBalanceState {
  final bool hideNetWorth;
  final bool hideAccountBalances;
  final bool hideTransactionAmounts;
  final bool hideAnalyticsAmounts;
  final bool hideDashboard;
  final bool hideAccountDetails;
  final bool hideCards;

  HideBalanceState({
    required this.hideNetWorth,
    required this.hideAccountBalances,
    required this.hideTransactionAmounts,
    required this.hideAnalyticsAmounts,
    required this.hideDashboard,
    required this.hideAccountDetails,
    required this.hideCards,
  });

  HideBalanceState copyWith({
    bool? hideNetWorth,
    bool? hideAccountBalances,
    bool? hideTransactionAmounts,
    bool? hideAnalyticsAmounts,
    bool? hideDashboard,
    bool? hideAccountDetails,
    bool? hideCards,
  }) {
    return HideBalanceState(
      hideNetWorth: hideNetWorth ?? this.hideNetWorth,
      hideAccountBalances: hideAccountBalances ?? this.hideAccountBalances,
      hideTransactionAmounts: hideTransactionAmounts ?? this.hideTransactionAmounts,
      hideAnalyticsAmounts: hideAnalyticsAmounts ?? this.hideAnalyticsAmounts,
      hideDashboard: hideDashboard ?? this.hideDashboard,
      hideAccountDetails: hideAccountDetails ?? this.hideAccountDetails,
      hideCards: hideCards ?? this.hideCards,
    );
  }
}

class HideBalanceNotifier extends StateNotifier<HideBalanceState> {
  final Ref _ref;

  HideBalanceNotifier(this._ref)
      : super(HideBalanceState(
          hideNetWorth: false,
          hideAccountBalances: false,
          hideTransactionAmounts: false,
          hideAnalyticsAmounts: false,
          hideDashboard: false,
          hideAccountDetails: false,
          hideCards: false,
        )) {
    // Listen to changes in the central appSettingsProvider
    _ref.listen<AppSettingsState>(
      appSettingsProvider,
      (previous, next) {
        state = HideBalanceState(
          hideNetWorth: next.hideNetWorth,
          hideAccountBalances: next.hideAccountBalances,
          hideTransactionAmounts: next.hideTransactionAmounts,
          hideAnalyticsAmounts: next.hideAnalyticsAmounts,
          hideDashboard: next.hideDashboard,
          hideAccountDetails: next.hideAccountDetails,
          hideCards: next.hideCards,
        );
      },
      fireImmediately: true,
    );
  }

  Future<void> toggleHideNetWorth() async {
    final current = _ref.read(appSettingsProvider).hideNetWorth;
    await _ref.read(appSettingsProvider.notifier).setSetting('hideNetWorth', !current);
  }

  Future<void> toggleHideAccountBalances() async {
    final current = _ref.read(appSettingsProvider).hideAccountBalances;
    await _ref.read(appSettingsProvider.notifier).setSetting('hideAccountBalances', !current);
  }

  Future<void> toggleHideTransactionAmounts() async {
    final current = _ref.read(appSettingsProvider).hideTransactionAmounts;
    await _ref.read(appSettingsProvider.notifier).setSetting('hideTransactionAmounts', !current);
  }

  Future<void> toggleHideAnalyticsAmounts() async {
    final current = _ref.read(appSettingsProvider).hideAnalyticsAmounts;
    await _ref.read(appSettingsProvider.notifier).setSetting('hideAnalyticsAmounts', !current);
  }

  Future<void> toggleHideDashboard() async {
    final current = _ref.read(appSettingsProvider).hideDashboard;
    await _ref.read(appSettingsProvider.notifier).setSetting('hideDashboard', !current);
  }

  Future<void> toggleHideAccountDetails() async {
    final current = _ref.read(appSettingsProvider).hideAccountDetails;
    await _ref.read(appSettingsProvider.notifier).setSetting('hideAccountDetails', !current);
  }

  Future<void> toggleHideCards() async {
    final current = _ref.read(appSettingsProvider).hideCards;
    await _ref.read(appSettingsProvider.notifier).setSetting('hideCards', !current);
  }

  Future<void> setHideAll(bool hide) async {
    await _ref.read(appSettingsProvider.notifier).setHideAll(hide);
  }
}

final hideBalanceProvider = StateNotifierProvider<HideBalanceNotifier, HideBalanceState>((ref) {
  return HideBalanceNotifier(ref);
});
