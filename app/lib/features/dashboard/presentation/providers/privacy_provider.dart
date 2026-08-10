import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/settings_provider.dart';

class PrivacyModeNotifier extends StateNotifier<bool> {
  final Ref _ref;

  PrivacyModeNotifier(this._ref) : super(false) {
    _ref.listen<AppSettingsState>(
      appSettingsProvider,
      (previous, next) {
        state = next.privacyModeEnabled;
      },
      fireImmediately: true,
    );
  }

  Future<void> toggle() async {
    final current = _ref.read(appSettingsProvider).privacyModeEnabled;
    await _ref.read(appSettingsProvider.notifier).setSetting('privacyModeEnabled', !current);
  }
}

final privacyModeProvider = StateNotifierProvider<PrivacyModeNotifier, bool>((ref) {
  return PrivacyModeNotifier(ref);
});
