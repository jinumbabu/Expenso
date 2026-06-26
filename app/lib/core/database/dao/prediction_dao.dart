import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/predictions.dart';

part 'prediction_dao.g.dart';

@DriftAccessor(tables: [FinancialPredictions])
class PredictionDao extends DatabaseAccessor<AppDatabase> with _$PredictionDaoMixin {
  PredictionDao(super.db);

  Future<List<FinancialPrediction>> getPredictionsForUser(String userId) =>
      (select(financialPredictions)..where((t) => t.userId.equals(userId))).get();

  Future<FinancialPrediction?> getLatestPrediction(String userId) =>
      (select(financialPredictions)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> insertPrediction(FinancialPrediction pred) => into(financialPredictions).insert(pred);
  Future<void> clearPredictions(String userId) =>
      (delete(financialPredictions)..where((t) => t.userId.equals(userId))).go();
}
