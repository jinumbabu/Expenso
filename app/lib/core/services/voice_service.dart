import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
      state = state.copyWith(isAvailable: available);
      return available;
    } catch (e) {
      state = state.copyWith(
        isAvailable: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> startListening({required Function(String) onResult}) async {
    state = state.copyWith(error: null, text: '');

    // Try initializing if not already available
    if (!state.isAvailable) {
      final ok = await initialize();
      if (!ok) {
        state = state.copyWith(error: 'Speech recognition is not available on this device');
        return;
      }
    }

    try {
      await _speech.listen(
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
