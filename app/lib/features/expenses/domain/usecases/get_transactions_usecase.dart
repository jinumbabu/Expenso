import '../repositories/expense_repository.dart';
import '../../../../core/database/app_database.dart';

class GetTransactionsUseCase {
  final ExpenseRepository _repository;

  GetTransactionsUseCase(this._repository);

  Future<List<Transaction>> execute(String userId) async {
    final transactions = await _repository.getTransactionsForUser(userId);
    // Sort by date descending (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }
}
