import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:app/core/services/ocr_service.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/core/network/dio_client.dart';

// Mock Ref
class MockRef implements Ref {
  final Map<dynamic, dynamic> _providers = {};

  void overrideProvider(dynamic provider, dynamic value) {
    _providers[provider] = value;
  }

  @override
  T read<T>(ProviderListenable<T> provider) {
    if (_providers.containsKey(provider)) {
      return _providers[provider] as T;
    }
    throw Exception('Provider not mocked: $provider');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock Dio
class MockDio extends Fake implements Dio {
  bool shouldFail = false;
  Map<String, dynamic>? responseData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (shouldFail) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network connection failed',
      );
    }

    if (path == '/ai/ocr') {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: (responseData ?? {
          'merchant': 'Target Scanned',
          'amount': 45.99,
          'category': 'Shopping',
          'date': '2026-06-18',
          'confidence': 0.98,
        }) as T,
        statusCode: 200,
      );
    }
    throw UnimplementedError();
  }
}

// Mock DioClient
class MockDioClient extends Fake implements DioClient {
  @override
  final Dio dio;
  MockDioClient(this.dio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OcrService Tests', () {
    late MockRef mockRef;
    late MockDio mockDio;
    late MockDioClient mockDioClient;
    late OcrService ocrService;

    setUp(() {
      mockRef = MockRef();
      mockDio = MockDio();
      mockDioClient = MockDioClient(mockDio);
      mockRef.overrideProvider(dioClientProvider, mockDioClient);
      ocrService = OcrService(mockRef);

      // Mock MethodChannel for ML Kit
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('google_mlkit_text_recognizer'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'vision#startTextRecognizer') {
            return <dynamic, dynamic>{
              'text': '',
              'blocks': [],
            };
          }
          if (methodCall.method == 'vision#closeTextRecognizer') {
            return null;
          }
          return null;
        },
      );
    });

    test('scanReceipt successfully parses receipt details from backend API', () async {
      mockDio.shouldFail = false;
      mockDio.responseData = {
        'merchant': 'Starbucks Coffee',
        'amount': 5.75,
        'category': 'Food',
        'date': '2026-06-18',
        'confidence': 0.95,
      };

      final tempFile = File('${Directory.systemTemp.path}/test_receipt.png');
      await tempFile.writeAsBytes([0, 1, 2, 3]);
      
      final result = await ocrService.scanReceipt(tempFile);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      expect(result, isNotNull);
      expect(result!.merchant, equals('Starbucks Coffee'));
      expect(result.amount, equals(5.75));
      expect(result.category, equals('Food'));
      expect(result.date, equals('2026-06-18'));
      expect(result.confidence, equals(0.95));
    });

    test('scanReceipt throws exception on network failure when on-device recognition has no text', () async {
      mockDio.shouldFail = true;

      final tempFile = File('${Directory.systemTemp.path}/test_receipt.png');
      await tempFile.writeAsBytes([0, 1, 2, 3]);
      
      try {
        await expectLater(
          ocrService.scanReceipt(tempFile),
          throwsA(isA<DioException>()),
        );
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });
  });
}
