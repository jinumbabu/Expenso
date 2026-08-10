import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/dashboard/presentation/screens/ai_settings_screen.dart';
import 'package:app/core/security/secure_storage_service.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';

class FakeSecureStorage extends Fake implements SecureStorageService {
  String mode = 'offline';
  String provider = 'offline';
  final Map<String, String> models = {'gemini': 'gemini-2.5-flash'};
  final Map<String, String> keys = {};

  @override
  Future<String?> getAiMode() async => mode;
  @override
  Future<void> saveAiMode(String value) async {
    mode = value;
  }

  @override
  Future<String?> getAiProvider() async => provider;
  @override
  Future<void> saveAiProvider(String value) async {
    provider = value;
  }

  @override
  Future<String?> getAiModel(String provider) async => models[provider] ?? 'gemini-2.5-flash';
  @override
  Future<void> saveAiModel(String provider, String model) async {
    models[provider] = model;
  }

  @override
  Future<String?> getApiKey(String provider) async => keys[provider];
  @override
  Future<void> saveApiKey(String provider, String key) async {
    keys[provider] = key;
  }

  @override
  Future<void> saveSavedApiKeysJson(String provider, String jsonStr) async {
    keys['api_keys_list_$provider'] = jsonStr;
  }

  @override
  Future<String?> getSavedApiKeysJson(String provider) async {
    return keys['api_keys_list_$provider'];
  }

  @override
  Future<void> deleteSavedApiKeysJson(String provider) async {
    keys.remove('api_keys_list_$provider');
  }

  @override
  Future<void> saveActiveKeyId(String provider, String keyId) async {
    keys['active_key_id_$provider'] = keyId;
  }

  @override
  Future<String?> getActiveKeyId(String provider) async {
    return keys['active_key_id_$provider'];
  }

  @override
  Future<void> deleteActiveKeyId(String provider) async {
    keys.remove('active_key_id_$provider');
  }
}

void main() {
  group('AiSettingsScreen Widget Tests', () {
    testWidgets('Renders layout and initial offline state correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          ],
          child: const MaterialApp(
            home: AiSettingsScreen(),
          ),
        ),
      );

      // Verify page title and header explanation
      expect(find.text('AI SETTINGS'), findsOneWidget);
      expect(find.textContaining('Configure Expenso\'s intelligence settings'), findsOneWidget);

      // Verify presence of Offline AI and Online AI cards
      expect(find.text('Offline AI'), findsOneWidget);
      expect(find.text('Online AI'), findsOneWidget);

      // Since mode is offline initially, no provider selection or key field should be visible yet
      expect(find.text('ONLINE AI PROVIDER'), findsNothing);
      expect(find.text('Validate API Key'), findsNothing);
    });

    testWidgets('Tapping Online AI shows Provider selector dropdown', (tester) async {
      tester.view.physicalSize = const Size(800, 1500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          ],
          child: const MaterialApp(
            home: AiSettingsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Tap on Online AI Mode Card
      await tester.tap(find.text('Online AI'));
      await tester.pumpAndSettle();

      // Verify provider dropdown and key inputs render
      expect(find.text('ONLINE AI PROVIDER'), findsOneWidget);
      expect(find.text('MODEL'), findsOneWidget);
      expect(find.text('API Keys Manager'), findsOneWidget);
    });
  });
}
