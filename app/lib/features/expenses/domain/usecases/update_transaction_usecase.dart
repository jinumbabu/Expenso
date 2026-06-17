import '../repositories/expense_repository.dart';
import '../../../../core/database/app_database.dart';

class UpdateTransactionUseCase {
  final ExpenseRepository _repository;

  UpdateTransactionUseCase(this._repository);

  Future<void> execute(Transaction transaction) async {
    await _repository.updateTransaction(transaction);
  }
}
