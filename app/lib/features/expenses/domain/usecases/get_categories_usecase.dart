import '../repositories/expense_repository.dart';
import '../../../../core/database/app_database.dart';

class GetCategoriesUseCase {
  final ExpenseRepository _repository;

  GetCategoriesUseCase(this._repository);

  Future<List<Category>> execute(String userId) async {
    final categories = await _repository.getCategoriesForUser(userId);
    // Sort categories: usageCount DESC, then name ASC
    categories.sort((a, b) {
      final usageCompare = b.usageCount.compareTo(a.usageCount);
      if (usageCompare != 0) return usageCompare;
      return a.name.compareTo(b.name);
    });
    return categories;
  }
}
