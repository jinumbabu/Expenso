import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceState {
  final bool isListening;
  final String text;
  final String? error;
  final bool isAvailable;

  VoiceState({
    this.isListening = false,
    this.text = '',
    this.error,
    this.isAvailable = false,
  });

  VoiceState copyWith({
    bool? isListening,
    String? text,
    String? error,
    bool? isAvailable,
  }) {
    return VoiceState(
      isListening: isListening ?? this.isListening,
      text: text ?? this.text,
      error: error ?? this.error,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class VoiceService extends StateNotifier<VoiceState> {
  final SpeechToText _speech;

  VoiceService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText(),
        super(VoiceState());

  Future<bool> initialize() async {
    // Check and request microphone permission
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      final newStatus = await Permission.microphone.request();
      if (newStatus.isDenied) {
        state = state.copyWith(
          isAvailable: false,
          error: 'Microphone permission denied. Please enable it in Settings.',
        );
        return false;
      }
    } else if (status.isPermanentlyDenied) {
      state = state.copyWith(
        isAvailable: false,
        error: 'Microphone permission permanently denied. Please enable it in Settings.',
      );
      return false;
    }

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'listening') {
            state = state.copyWith(isListening: true);
          } else if (status == 'notListening' || status == 'done') {
            state = state.copyWith(isListening: false);
          }
        },
        onError: (errorNotification) {
          state = state.copyWith(
            isListening: false,
            error: errorNotification.errorMsg,
          );
        },
      );
      state = state.copyWith(isAvailable: available, error: null);
      return available;
    } catch (e) {
      state = state.copyWith(
        isAvailable: false,
        error: 'STT init error: $e',
      );
      return false;
    }
  }

  Future<void> startListening({required Function(String) onResult, String? localeId}) async {
    state = state.copyWith(error: null, text: '');

    // Try initializing if not already available (with auto-retry)
    if (!state.isAvailable) {
      var ok = await initialize();
      if (!ok) {
        // Retry once after a brief delay
        await Future.delayed(const Duration(milliseconds: 500));
        ok = await initialize();
        if (!ok) {
          if (state.error == null) {
            state = state.copyWith(error: 'Speech recognition is not available on this device');
          }
          return;
        }
      }
    }

    try {
      await _speech.listen(
        localeId: localeId,
        onResult: (result) {
          state = state.copyWith(text: result.recognizedWords);
          onResult(result.recognizedWords);
        },
      );
      state = state.copyWith(isListening: true);
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: e.toString(),
      );
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
      state = state.copyWith(isListening: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
      state = state.copyWith(isListening: false, text: '');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final voiceServiceProvider = StateNotifierProvider<VoiceService, VoiceState>((ref) {
  return VoiceService();
});
