import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/app_database.dart';
import '../../../../core/services/category_intelligence.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import 'quick_create_category_sheet.dart';

class SearchableCategoryBottomSheet extends ConsumerStatefulWidget {
  final String transactionType; // 'expense', 'income'
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;

  const SearchableCategoryBottomSheet({
    super.key,
    required this.transactionType,
    this.selectedCategoryId,
    this.selectedSubcategoryId,
  });

  @override
  ConsumerState<SearchableCategoryBottomSheet> createState() => _SearchableCategoryBottomSheetState();
}

class _SearchableCategoryBottomSheetState extends ConsumerState<SearchableCategoryBottomSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Category? _selectedParentCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(Category cat) {
    if (cat.color != null && cat.color!.isNotEmpty) {
      try {
        return Color(int.parse(cat.color!));
      } catch (_) {}
    }
    return CategoryIntelligence.getColorForName(cat.name);
  }

  IconData _getCategoryIcon(Category cat) {
    return CategoryIntelligence.getIconForName(cat.name);
  }

  bool _matchesQuery(Category cat, List<Category> allCategories, String query) {
    if (query.isEmpty) return true;
    final name = cat.name.toLowerCase();
    if (name.contains(query)) return true;

    if (cat.parentId != null) {
      final parent = allCategories.firstWhere((c) => c.id == cat.parentId, orElse: () => null as dynamic);
      if (parent != null && parent.name.toLowerCase().contains(query)) {
        return true;
      }
    }

    if (cat.icon != null && cat.icon!.toLowerCase().contains(query)) {
      return true;
    }

    final Map<String, List<String>> aliases = {
      'groceries': ['gro', 'grocery', 'food', 'market', 'blinkit', 'instamart', 'bigbasket'],
      'fuel': ['pet', 'petrol', 'diesel', 'gas', 'cng', 'transport', 'car', 'bike', 'oil'],
      'restaurant': ['res', 'dine', 'dinner', 'lunch', 'eat', 'swiggy', 'zomato'],
      'shopping': ['shop', 'amazon', 'flipkart', 'buy', 'clothes'],
      'salary': ['income', 'salary', 'pay', 'earned'],
      'medical': ['health', 'doctor', 'hospital', 'medicine', 'pharmacy'],
      'electricity': ['power', 'bill', 'utility'],
    };

    for (var entry in aliases.entries) {
      if (name.contains(entry.key)) {
        if (entry.value.any((alias) => alias.contains(query) || query.contains(alias))) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> _openQuickCreateCategory({Category? parentCategory}) async {
    final result = await showModalBottomSheet<Category?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickCreateCategorySheet(
        initialName: _searchQuery,
        transactionType: widget.transactionType,
        initialParentId: parentCategory?.id,
      ),
    );

    if (result != null && mounted) {
      final db = ref.read(databaseProvider);
      final categories = await db.categoryDao.getCategoriesForUser(result.userId);
      Category? parentCat = result;
      Category? subCat;

      if (result.parentId != null) {
        subCat = result;
        parentCat = categories.firstWhere((c) => c.id == result.parentId, orElse: () => result);
      }

      Navigator.pop(context, {'category': parentCat, 'subcategory': subCat});
    }
  }

  Future<void> _editCategory(Category cat) async {
    final result = await showModalBottomSheet<Category?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickCreateCategorySheet(
        initialName: cat.name,
        transactionType: widget.transactionType,
        initialParentId: cat.parentId,
        categoryToEdit: cat,
      ),
    );

    if (result != null) {
      ref.invalidate(categoriesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "${result.name}" updated successfully.')),
      );
    }
  }

  Future<void> _duplicateCategory(Category cat) async {
    final auth = ref.read(authProvider);
    final userId = auth.user?.id;
    if (userId == null) return;

    final db = ref.read(databaseProvider);
    final newId = const Uuid().v4();
    final duplicated = Category(
      id: newId,
      userId: userId,
      name: '${cat.name} Copy',
      type: cat.type,
      parentId: cat.parentId,
      icon: cat.icon,
      color: cat.color,
      isSystemDefault: false,
      createdAt: DateTime.now(),
      usageCount: 0,
    );

    try {
      await db.categoryDao.insertCategory(duplicated);
      ref.invalidate(categoriesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicated "${cat.name}" as "${duplicated.name}".')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to duplicate category: $e')),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteCategory(Category cat, List<Category> allCategories) async {
    final db = ref.read(databaseProvider);
    final subcategories = allCategories.where((c) => c.parentId == cat.id).toList();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D121B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        title: const Text('Delete Category?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          subcategories.isNotEmpty
              ? 'Warning: "${cat.name}" contains ${subcategories.length} subcategories. Deleting it will delete all its subcategories. Are you sure?'
              : 'Are you sure you want to delete "${cat.name}"?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (subcategories.isNotEmpty) {
          for (var sub in subcategories) {
            await db.categoryDao.deleteCategory(sub.id);
          }
        }
        await db.categoryDao.deleteCategory(cat.id);
        ref.invalidate(categoriesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${cat.name}" category.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete category: $e')),
          );
        }
      }
    }
  }

  Future<void> _moveCategory(Category cat, List<Category> allCategories) async {
    final parentCategories = allCategories
        .where((c) => c.parentId == null && c.id != cat.id && c.type == widget.transactionType)
        .toList();

    final selectedParent = await showDialog<Category?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D121B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select New Parent Category', style: TextStyle(color: Colors.white, fontSize: 15)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('None (Make Parent Category)', style: TextStyle(color: Colors.white54)),
                onTap: () => Navigator.pop(context, null),
              ),
              ...parentCategories.map((p) => ListTile(
                    title: Text(p.name, style: const TextStyle(color: Colors.white70)),
                    onTap: () => Navigator.pop(context, p),
                  )),
            ],
          ),
        ),
      ),
    );

    final db = ref.read(databaseProvider);
    try {
      final updated = cat.copyWith(parentId: Value(selectedParent?.id));
      await db.categoryDao.updateCategory(updated);
      ref.invalidate(categoriesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedParent != null
                  ? 'Moved "${cat.name}" under "${selectedParent.name}".'
                  : 'Converted "${cat.name}" to parent category.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move category: $e')),
        );
      }
    }
  }

  void _showCategoryManagementSheet(BuildContext context, Category cat, List<Category> allCategories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D121B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Manage "${cat.name}"',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Color(0xFF0066FF)),
                  title: const Text('Edit Details', style: TextStyle(color: Colors.white70)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _editCategory(cat);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_outlined, color: Colors.green),
                  title: const Text('Duplicate', style: TextStyle(color: Colors.white70)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _duplicateCategory(cat);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Delete', style: TextStyle(color: Colors.white70)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _confirmAndDeleteCategory(cat, allCategories);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.drive_file_move_outlined, color: Color(0xFF00E5FF)),
                  title: const Text('Move to Another Parent', style: TextStyle(color: Colors.white70)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _moveCategory(cat, allCategories);
                  },
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.cancel_outlined, color: Colors.white30),
                  title: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0D121B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedParentCategory != null
                      ? _selectedParentCategory!.name
                      : 'Select Category',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar & "+ New" Button
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white38, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Search categories...',
                              hintStyle: TextStyle(color: Colors.white30),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                            onPressed: () => _searchController.clear(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openQuickCreateCategory(parentCategory: _selectedParentCategory),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content Area
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  final typeCats = categories.where((c) => c.type == widget.transactionType).toList();
                  final parentCats = typeCats.where((c) => c.parentId == null).toList();
                  final subCats = typeCats.where((c) => c.parentId != null).toList();

                  // Smart Search filtering
                  if (_searchQuery.isNotEmpty) {
                    final searchResults = typeCats.where((c) => _matchesQuery(c, typeCats, _searchQuery)).toList();

                    if (searchResults.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: Colors.white24),
                            const SizedBox(height: 12),
                            Text('No categories match "$_searchQuery"', style: const TextStyle(color: Colors.white54)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: searchResults.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                      itemBuilder: (context, index) {
                        final cat = searchResults[index];
                        final isSub = cat.parentId != null;
                        Category? parent;
                        if (isSub) {
                          parent = typeCats.firstWhere((c) => c.id == cat.parentId, orElse: () => cat);
                        }

                        final displayColor = _getCategoryColor(cat);
                        final displayIcon = _getCategoryIcon(cat);

                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onLongPress: () => _showCategoryManagementSheet(context, cat, typeCats),
                          onTap: () {
                            if (isSub) {
                              Navigator.pop(context, {'category': parent, 'subcategory': cat});
                            } else {
                              Navigator.pop(context, {'category': cat, 'subcategory': null});
                            }
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: displayColor.withOpacity(0.15), shape: BoxShape.circle),
                            child: Icon(displayIcon, color: displayColor, size: 20),
                          ),
                          title: Text(
                            isSub ? '${parent!.name} > ${cat.name}' : cat.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                        );
                      },
                    );
                  }

                  // Nested category subcategories view
                  if (_selectedParentCategory != null) {
                    final subs = subCats.where((s) => s.parentId == _selectedParentCategory!.id).toList();

                    return Column(
                      children: [
                        ListTile(
                          onTap: () => setState(() => _selectedParentCategory = null),
                          leading: const Icon(Icons.arrow_back, color: Colors.white54),
                          title: const Text('Back to all categories', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: subs.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              if (index == subs.length) {
                                // Add default "Other" option inside subcategory list
                                return ListTile(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  onTap: () {
                                    Navigator.pop(context, {'category': _selectedParentCategory!, 'subcategory': null});
                                  },
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                                    child: const Icon(Icons.folder_open_outlined, color: Colors.white54, size: 20),
                                  ),
                                  title: const Text('Other', style: TextStyle(color: Colors.white70, fontSize: 14.5)),
                                );
                              }

                              final sub = subs[index];
                              final subColor = _getCategoryColor(sub);
                              final subIcon = _getCategoryIcon(sub);

                              return ListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                onLongPress: () => _showCategoryManagementSheet(context, sub, typeCats),
                                onTap: () {
                                  Navigator.pop(context, {'category': _selectedParentCategory!, 'subcategory': sub});
                                },
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: subColor.withOpacity(0.15), shape: BoxShape.circle),
                                  child: Icon(subIcon, color: subColor, size: 20),
                                ),
                                title: Text(sub.name, style: const TextStyle(color: Colors.white70, fontSize: 14.5)),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  // Default categories dashboard view (Favorites + Recent + All Categories)
                  final freqUsed = typeCats.where((c) => c.usageCount > 0).toList();
                  freqUsed.sort((a, b) => b.usageCount.compareTo(a.usageCount));
                  final favorites = freqUsed.take(5).toList();

                  final recCats = typeCats.where((c) => c.lastUsedAt != null).toList();
                  recCats.sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
                  final recents = recCats.take(3).toList();

                  return ListView(
                    children: [
                      // Frequently Used
                      if (favorites.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(Icons.star_outline, color: Colors.amber, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Frequently Used',
                              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: favorites.map((cat) {
                            final isSub = cat.parentId != null;
                            Category? parent;
                            if (isSub) {
                              parent = typeCats.firstWhere((c) => c.id == cat.parentId, orElse: () => cat);
                            }
                            final catColor = _getCategoryColor(cat);

                            return InkWell(
                              onTap: () {
                                if (isSub) {
                                  Navigator.pop(context, {'category': parent, 'subcategory': cat});
                                } else {
                                  Navigator.pop(context, {'category': cat, 'subcategory': null});
                                }
                              },
                              onLongPress: () => _showCategoryManagementSheet(context, cat, typeCats),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: catColor.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getCategoryIcon(cat), color: catColor, size: 15),
                                    const SizedBox(width: 6),
                                    Text(cat.name, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Recents
                      if (recents.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(Icons.history, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Recent',
                              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: recents.map((cat) {
                            final isSub = cat.parentId != null;
                            Category? parent;
                            if (isSub) {
                              parent = typeCats.firstWhere((c) => c.id == cat.parentId, orElse: () => cat);
                            }
                            final catColor = _getCategoryColor(cat);

                            return InkWell(
                              onTap: () {
                                if (isSub) {
                                  Navigator.pop(context, {'category': parent, 'subcategory': cat});
                                } else {
                                  Navigator.pop(context, {'category': cat, 'subcategory': null});
                                }
                              },
                              onLongPress: () => _showCategoryManagementSheet(context, cat, typeCats),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getCategoryIcon(cat), color: catColor, size: 15),
                                    const SizedBox(width: 6),
                                    Text(cat.name, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // All Categories
                      const Row(
                        children: [
                          Icon(Icons.category_outlined, color: Color(0xFF00E5FF), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'All Categories',
                            style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ...parentCats.map((parent) {
                        final parentColor = _getCategoryColor(parent);
                        final parentIcon = _getCategoryIcon(parent);
                        final subsCount = subCats.where((s) => s.parentId == parent.id).length;

                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onLongPress: () => _showCategoryManagementSheet(context, parent, typeCats),
                          onTap: () {
                            if (subsCount > 0) {
                              setState(() => _selectedParentCategory = parent);
                            } else {
                              Navigator.pop(context, {'category': parent, 'subcategory': null});
                            }
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: parentColor.withOpacity(0.15), shape: BoxShape.circle),
                            child: Icon(parentIcon, color: parentColor, size: 20),
                          ),
                          title: Text(parent.name, style: const TextStyle(color: Colors.white70, fontSize: 14.5, fontWeight: FontWeight.w500)),
                          trailing: subsCount > 0
                              ? const Icon(Icons.chevron_right, color: Colors.white30, size: 18)
                              : null,
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0066FF)),
                ),
                error: (err, _) => Center(
                  child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
