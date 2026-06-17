import '../repositories/expense_repository.dart';
import '../../../../core/database/app_database.dart';

class CreateTransactionUseCase {
  final ExpenseRepository _repository;

  CreateTransactionUseCase(this._repository);

  Future<void> execute(Transaction transaction) async {
    await _repository.createTransaction(transaction);
    if (transaction.categoryId != null) {
      await _repository.incrementCategoryUsage(transaction.categoryId!);
    }
  }
}
