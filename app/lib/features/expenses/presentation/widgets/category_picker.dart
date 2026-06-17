import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../providers/expense_provider.dart';

class CategoryPicker extends ConsumerWidget {
  final String? selectedCategoryId;
  final ValueChanged<Category> onCategorySelected;
  final String transactionType; // 'expense' or 'income'

  const CategoryPicker({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.transactionType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        // Filter categories based on transaction type (expense vs income)
        final filteredCats = categories
            .where((cat) => cat.type == transactionType)
            .toList();

        if (filteredCats.isEmpty) {
          return const Center(
            child: Text(
              'No categories found',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: filteredCats.length,
            itemBuilder: (context, index) {
              final cat = filteredCats[index];
              final isSelected = cat.id == selectedCategoryId;
              final color = IconMapper.getColor(cat.icon);
              final icon = IconMapper.getIcon(cat.icon);

              return GestureDetector(
                onTap: () => onCategorySelected(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : Colors.white12,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : Colors.white70,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
