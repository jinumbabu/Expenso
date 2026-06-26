import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/reports.dart';

part 'report_dao.g.dart';

@DriftAccessor(tables: [FinancialReports])
class ReportDao extends DatabaseAccessor<AppDatabase> with _$ReportDaoMixin {
  ReportDao(super.db);

  Future<List<FinancialReport>> getReportsForUser(String userId) =>
      (select(financialReports)..where((t) => t.userId.equals(userId))).get();

  Future<FinancialReport?> getReportById(String id) =>
      (select(financialReports)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertReport(FinancialReport report) => into(financialReports).insert(report);
  Future<int> deleteReport(String id) =>
      (delete(financialReports)..where((t) => t.id.equals(id))).go();
}
