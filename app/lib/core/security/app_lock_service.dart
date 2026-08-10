import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_service.dart';

import 'package:flutter/services.dart';

class AppLockService {
  final SecureStorageService _secureStorage;
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const _securityChannel = MethodChannel('com.expenso.ai.app/security');

  AppLockService(this._secureStorage);

  // Secure PIN Hashing
  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    var digest = sha256.convert(bytes);
    for (int i = 0; i < 1000; i++) {
      digest = sha256.convert(digest.bytes);
    }
    return digest.toString();
  }

  String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }

  // --- PIN Configuration ---

  Future<bool> isPinSet(String userId) async {
    final hash = await _secureStorage.read('pin_hash_$userId');
    return hash != null && hash.isNotEmpty;
  }

  Future<void> savePin(String userId, String pin, {int length = 4}) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _secureStorage.write('pin_hash_$userId', hash);
    await _secureStorage.write('pin_salt_$userId', salt);
    await _secureStorage.write('pin_length_$userId', length.toString());
    await resetFailedAttempts(userId);
  }

  Future<bool> verifyPin(String userId, String pin) async {
    if (await isLockedOut(userId)) return false;

    final hash = await _secureStorage.read('pin_hash_$userId');
    final salt = await _secureStorage.read('pin_salt_$userId');
    if (hash == null || salt == null) return false;

    final computed = _hashPin(pin, salt);
    final verified = computed == hash;

    if (verified) {
      await resetFailedAttempts(userId);
    } else {
      await registerFailedAttempt(userId);
    }
    return verified;
  }

  Future<void> removePin(String userId) async {
    await _secureStorage.delete('pin_hash_$userId');
    await _secureStorage.delete('pin_salt_$userId');
    await _secureStorage.delete('pin_length_$userId');
    await _secureStorage.delete('biometric_enabled_$userId');
    await resetFailedAttempts(userId);
  }

  Future<int> getPinLength(String userId) async {
    final lenStr = await _secureStorage.read('pin_length_$userId');
    return int.tryParse(lenStr ?? '4') ?? 4;
  }

  // --- Biometrics Configuration ---

  Future<bool> canUseBiometrics() async {
    try {
      final hasBiometrics = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return hasBiometrics || isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled(String userId) async {
    final val = await _secureStorage.read('biometric_enabled_$userId');
    return val == 'true';
  }

  Future<void> setBiometricEnabled(String userId, bool enabled) async {
    await _secureStorage.write('biometric_enabled_$userId', enabled.toString());
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!await canUseBiometrics()) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock Expenso',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometrics authentication failed: $e');
      return false;
    }
  }

  // --- Lockout & Brute Force Protection ---

  Future<int> getFailedAttempts(String userId) async {
    final val = await _secureStorage.read('failed_pin_attempts_$userId');
    return int.tryParse(val ?? '0') ?? 0;
  }

  Future<void> registerFailedAttempt(String userId) async {
    final current = await getFailedAttempts(userId);
    final next = current + 1;
    await _secureStorage.write('failed_pin_attempts_$userId', next.toString());

    if (next >= 5) {
      final levelVal = await _secureStorage.read('lockout_level_$userId');
      final currentLevel = int.tryParse(levelVal ?? '0') ?? 0;

      int durationSeconds = 30;
      if (currentLevel == 1) {
        durationSeconds = 120; // 2 minutes
      } else if (currentLevel >= 2) {
        durationSeconds = 900; // 15 minutes
      }

      final expiration = DateTime.now().add(Duration(seconds: durationSeconds));
      await _secureStorage.write('lockout_expiration_$userId', expiration.toIso8601String());
      await _secureStorage.write('lockout_level_$userId', (currentLevel + 1).toString());
    }
  }

  Future<void> resetFailedAttempts(String userId) async {
    await _secureStorage.delete('failed_pin_attempts_$userId');
    await _secureStorage.delete('lockout_expiration_$userId');
    await _secureStorage.delete('lockout_level_$userId');
  }

  Future<bool> isLockedOut(String userId) async {
    final expStr = await _secureStorage.read('lockout_expiration_$userId');
    if (expStr == null) return false;

    final expiration = DateTime.tryParse(expStr);
    if (expiration == null) return false;

    if (DateTime.now().isAfter(expiration)) {
      // Expiration passed, clear expiration but keep failed attempts at 4 so next fail locks immediately
      await _secureStorage.delete('lockout_expiration_$userId');
      await _secureStorage.write('failed_pin_attempts_$userId', '4');
      return false;
    }
    return true;
  }

  Future<int> getRemainingLockoutSeconds(String userId) async {
    final expStr = await _secureStorage.read('lockout_expiration_$userId');
    if (expStr == null) return 0;

    final expiration = DateTime.tryParse(expStr);
    if (expiration == null) return 0;

    final diff = expiration.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  // --- Auto Lock Timer Settings ---
  // Store dynamic inactivity timeouts (in seconds)
  Future<int> getAutoLockTimer(String userId) async {
    final val = await _secureStorage.read('auto_lock_timer_$userId');
    // Default to -1 (Never)
    return int.tryParse(val ?? '-1') ?? -1;
  }

  Future<void> saveAutoLockTimer(String userId, int seconds) async {
    await _secureStorage.write('auto_lock_timer_$userId', seconds.toString());
  }

  // --- Screen Security (Prevent Screenshots) ---
  Future<bool> isScreenSecurityEnabled(String userId) async {
    final val = await _secureStorage.read('screen_security_enabled_$userId');
    return val == 'true';
  }

  Future<void> applyScreenSecurity(String userId) async {
    try {
      final enabled = await isScreenSecurityEnabled(userId);
      await _securityChannel.invokeMethod('setSecureScreen', {'secure': enabled});
    } catch (e) {
      debugPrint('Failed to apply screen security natively: $e');
    }
  }

  Future<void> setScreenSecurityEnabled(String userId, bool enabled) async {
    await _secureStorage.write('screen_security_enabled_$userId', enabled.toString());
    await applyScreenSecurity(userId);
  }
}

// Provider definition

final appLockServiceProvider = Provider<AppLockService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AppLockService(secureStorage);
});
