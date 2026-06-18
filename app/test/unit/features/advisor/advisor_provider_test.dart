import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'package:app/features/advisor/presentation/providers/advisor_provider.dart';
import 'package:app/core/database/app_database.dart';
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
  void invalidate(ProviderOrFamily provider) {
    // No-op in mock
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock Dio for testing API insights
class MockDio extends Fake implements Dio {
  bool shouldFail = false;

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

    if (path == '/ai/insights') {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: {
          'insights': [
            'AI recommendation: Save more on Food.',
            'Your monthly forecast is within normal range.',
            'Consider creating a shopping budget constraint.'
          ]
        } as T,
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
  group('AdvisorNotifier Tests', () {
    late MockRef mockRef;
    late AppDatabase database;
    late MockDio mockDio;
    late MockDioClient mockDioClient;
    late String userId;

    setUp(() async {
      mockRef = MockRef();
      database = AppDatabase.connect(NativeDatabase.memory());
      mockDio = MockDio();
      mockDioClient = MockDioClient(mockDio);
      userId = 'user-advisor-123';

      final testUser = User(
        id: userId,
        googleId: 'google-advisor-id',
        email: 'advisor@expenso.ai',
        displayName: 'Advisor User',
        currency: 'INR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockRef.overrideProvider(authProvider, AuthState.authenticated(testUser));
      mockRef.overrideProvider(databaseProvider, database);
      mockRef.overrideProvider(dioClientProvider, mockDioClient);

      // Seed core categories
      await database.categoryDao.insertCategory(
        Category(
          id: 'cat-food',
          userId: userId,
          name: 'Food',
          type: 'expense',
          usageCount: 0,
          isSystemDefault: false,
          createdAt: DateTime.now(),
        ),
      );
      await database.categoryDao.insertCategory(
        Category(
          id: 'cat-utilities',
          userId: userId,
          name: 'Utilities',
          type: 'expense',
          usageCount: 0,
          isSystemDefault: false,
          createdAt: DateTime.now(),
        ),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('Initializes with default state', () {
      final notifier = AdvisorNotifier(mockRef);
      final state = notifier.state;

      expect(state.healthScore, equals(100));
      expect(state.healthStatus, equals('Excellent'));
      expect(state.totalIncome, equals(0));
      expect(state.totalExpense, equals(0));
    });

    test('Calculates health score and forecasting with transaction logs correctly', () async {
      // 1. Seed Income
      await database.transactionDao.insertTransaction(
        Transaction(
          id: const Uuid().v4(),
          userId: userId,
          amount: 5000000, // ₹50,000
          type: 'income',
          currency: 'INR',
          date: DateTime.now(),
          isRecurring: false,
          source: 'manual',
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // 2. Seed Expense (within budget)
      await database.transactionDao.insertTransaction(
        Transaction(
          id: const Uuid().v4(),
          userId: userId,
          categoryId: 'cat-food',
          amount: 1500000, // ₹15,000
          type: 'expense',
          currency: 'INR',
          date: DateTime.now(),
          isRecurring: false,
          source: 'manual',
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // 3. Seed Budget limit: ₹20,000
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      await database.budgetDao.insertBudget(
        Budget(
          id: 'budget-food',
          userId: userId,
          categoryId: 'cat-food',
          amount: 2000000, // ₹20,000
          period: 'monthly',
          startDate: startOfMonth,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final notifier = AdvisorNotifier(mockRef);
      await notifier.calculateFinancialOverview();

      final state = notifier.state;

      expect(state.totalIncome, equals(5000000));
      expect(state.totalExpense, equals(1500000));
      expect(state.healthScore, greaterThanOrEqualTo(80));
      expect(state.healthStatus, equals('Excellent'));

      // Month-End forecast test
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final expectedForecast = (1500000 ~/ now.day) * daysInMonth;
      expect(state.projectedMonthEndSpend, equals(expectedForecast));
    });

    test('Loads cloud insights successfully when online', () async {
      mockDio.shouldFail = false;

      final notifier = AdvisorNotifier(mockRef);
      await notifier.loadInsights();

      expect(notifier.state.aiInsights.length, equals(3));
      expect(notifier.state.aiInsights[0], contains('Save more on Food'));
      expect(notifier.state.isLoadingInsights, isFalse);
    });

    test('Falls back to local rule-based insights when offline', () async {
      mockDio.shouldFail = true;

      final notifier = AdvisorNotifier(mockRef);
      await notifier.loadInsights();

      expect(notifier.state.aiInsights.length, equals(3));
      expect(notifier.state.aiInsights[0], contains('recorded this month')); // initial fallback
      expect(notifier.state.isLoadingInsights, isFalse);
    });
  });
}
