import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:app/core/services/voice_service.dart';
import 'package:flutter/services.dart';

class MockSpeechToText extends Fake implements SpeechToText {
  bool availableResult = true;
  bool shouldThrow = false;
  dynamic onStatusCallback;
  dynamic onErrorCallback;
  dynamic onResultCallback;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.contains('initialize')) {
      if (shouldThrow) throw Exception('STT Init Failed');
      onStatusCallback = invocation.namedArguments[#onStatus];
      onErrorCallback = invocation.namedArguments[#onError];
      return Future.value(availableResult);
    }
    if (name.contains('listen')) {
      if (shouldThrow) throw Exception('STT Listen Failed');
      onResultCallback = invocation.namedArguments[#onResult];
      if (onStatusCallback != null) {
        onStatusCallback!('listening');
      }
      return Future.value();
    }
    if (name.contains('stop') || name.contains('cancel')) {
      if (onStatusCallback != null) {
        onStatusCallback!('notListening');
      }
      return Future.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class MockSpeechRecognitionResult extends Fake implements SpeechRecognitionResult {
  @override
  final String recognizedWords;
  @override
  final bool finalResult;

  MockSpeechRecognitionResult(this.recognizedWords, {this.finalResult = true});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('VoiceService Tests', () {
    late MockSpeechToText mockSpeech;
    late VoiceService voiceService;

    setUp(() {
      mockSpeech = MockSpeechToText();
      voiceService = VoiceService(speech: mockSpeech);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'checkPermissionStatus') {
            return 1; // PermissionStatus.granted
          }
          return null;
        },
      );
    });

    test('Initializes successfully when speech recognition is available', () async {
      mockSpeech.availableResult = true;
      
      final available = await voiceService.initialize();

      expect(available, isTrue);
      expect(voiceService.state.isAvailable, isTrue);
      expect(voiceService.state.error, isNull);
    });

    test('Fails initialization when speech recognition is not available', () async {
      mockSpeech.availableResult = false;
      
      final available = await voiceService.initialize();

      expect(available, isFalse);
      expect(voiceService.state.isAvailable, isFalse);
      expect(voiceService.state.error, isNull);
    });

    test('Handles exceptions during initialization gracefully', () async {
      mockSpeech.shouldThrow = true;
      
      final available = await voiceService.initialize();

      expect(available, isFalse);
      expect(voiceService.state.isAvailable, isFalse);
      expect(voiceService.state.error, contains('STT Init Failed'));
    });

    test('startListening sets state to listening and passes results', () async {
      mockSpeech.availableResult = true;
      await voiceService.initialize();

      String? transcriptionResult;
      await voiceService.startListening(onResult: (text) {
        transcriptionResult = text;
      });

      expect(voiceService.state.isListening, isTrue);

      // Simulate recognition result
      if (mockSpeech.onResultCallback != null) {
        mockSpeech.onResultCallback!(
          MockSpeechRecognitionResult('spent 200 on grocery'),
        );
      }

      expect(voiceService.state.text, equals('spent 200 on grocery'));
      expect(transcriptionResult, equals('spent 200 on grocery'));
    });

    test('stopListening stops listening and updates status', () async {
      mockSpeech.availableResult = true;
      await voiceService.initialize();
      await voiceService.startListening(onResult: (_) {});

      expect(voiceService.state.isListening, isTrue);

      await voiceService.stopListening();

      expect(voiceService.state.isListening, isFalse);
    });

    test('cancelListening cancels listening, resets state text', () async {
      mockSpeech.availableResult = true;
      await voiceService.initialize();
      await voiceService.startListening(onResult: (_) {});
      
      if (mockSpeech.onResultCallback != null) {
        mockSpeech.onResultCallback!(MockSpeechRecognitionResult('some text'));
      }
      expect(voiceService.state.text, equals('some text'));

      await voiceService.cancelListening();

      expect(voiceService.state.isListening, isFalse);
      expect(voiceService.state.text, isEmpty);
    });
  });
}
