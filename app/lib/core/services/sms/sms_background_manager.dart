import 'dart:io';
import 'package:flutter/services.dart';

class SmsBackgroundManager {
  static const MethodChannel _channel = MethodChannel('com.expenso.ai.app/sms');

  Future<bool> checkReceiverAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      // In Android, because the receiver is declared statically in the manifest,
      // it is always available to the system.
      return true;
    } catch (_) {
      return false;
    }
  }
}
