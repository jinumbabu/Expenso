import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getCategoriesForUser(String userId) =>
      (select(categories)..where((t) => t.userId.equals(userId) | t.isSystemDefault.equals(true))).get();

  Future<Category?> getCategoryById(String id) =>
      (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertCategory(Category category) => into(categories).insert(category);
  Future<bool> updateCategory(Category category) => update(categories).replace(category);
  Future<int> deleteCategory(String id) =>
      (delete(categories)..where((t) => t.id.equals(id))).go();

  Future<void> incrementCategoryUsage(String categoryId) async {
    final cat = await getCategoryById(categoryId);
    if (cat != null) {
      final updated = cat.copyWith(
        usageCount: cat.usageCount + 1,
        lastUsedAt: Value(DateTime.now()),
      );
      await updateCategory(updated);
    }
  }
}
