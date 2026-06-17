import '../repositories/expense_repository.dart';
import '../../../../core/database/app_database.dart';

class GetPaymentMethodsUseCase {
  final ExpenseRepository _repository;

  GetPaymentMethodsUseCase(this._repository);

  Future<List<PaymentMethod>> execute(String userId) async {
    return await _repository.getPaymentMethodsForUser(userId);
  }
}
