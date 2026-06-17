import '../repositories/expense_repository.dart';

class DeleteTransactionUseCase {
  final ExpenseRepository _repository;

  DeleteTransactionUseCase(this._repository);

  Future<void> execute(String transactionId) async {
    await _repository.softDeleteTransaction(transactionId);
  }
}
