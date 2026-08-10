import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/app_database.dart';
import '../../../../core/services/category_intelligence.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/expense_provider.dart';

class QuickCreateCategoryDialog extends ConsumerStatefulWidget {
  final String initialName;
  final String transactionType; // 'expense', 'income'
  final String? initialParentId;

  const QuickCreateCategoryDialog({
    super.key,
    required this.initialName,
    required this.transactionType,
    this.initialParentId,
  });

  @override
  ConsumerState<QuickCreateCategoryDialog> createState() => _QuickCreateCategoryDialogState();
}

class _QuickCreateCategoryDialogState extends ConsumerState<QuickCreateCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedParentId;
  late String _selectedIconKey;
  late Color _selectedColor;

  final List<Map<String, dynamic>> _availableIcons = [
    {'key': 'fastfood', 'icon': Icons.fastfood_outlined},
    {'key': 'restaurant', 'icon': Icons.restaurant_outlined},
    {'key': 'coffee', 'icon': Icons.coffee_outlined},
    {'key': 'local_gas_station', 'icon': Icons.local_gas_station_outlined},
    {'key': 'flight', 'icon': Icons.flight_outlined},
    {'key': 'shopping_bag', 'icon': Icons.shopping_bag_outlined},
    {'key': 'shopping_cart', 'icon': Icons.shopping_cart_outlined},
    {'key': 'receipt_long', 'icon': Icons.receipt_long_outlined},
    {'key': 'electric_bolt', 'icon': Icons.electric_bolt_outlined},
    {'key': 'movie', 'icon': Icons.movie_outlined},
    {'key': 'payments', 'icon': Icons.payments_outlined},
    {'key': 'work', 'icon': Icons.work_outline},
    {'key': 'trending_up', 'icon': Icons.trending_up_outlined},
    {'key': 'card_giftcard', 'icon': Icons.card_giftcard_outlined},
    {'key': 'home', 'icon': Icons.home_outlined},
    {'key': 'favorite', 'icon': Icons.favorite_outlined},
    {'key': 'school', 'icon': Icons.school_outlined},
    {'key': 'folder', 'icon': Icons.folder_outlined},
  ];

  final List<Color> _availableColors = [
    const Color(0xFFFFA500), // Orange
    const Color(0xFF0066FF), // Blue
    const Color(0xFF8A2BE2), // Purple
    const Color(0xFFFFB703), // Yellow
    const Color(0xFFFF3B30), // Red
    const Color(0xFF00FF88), // Green
    const Color(0xFF00E5FF), // Cyan
    const Color(0xFFEC4899), // Pink
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Violet
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedParentId = widget.initialParentId;
    
    // Auto detect best icon and color
    _selectedIconKey = CategoryIntelligence.getIconKeyForName(widget.initialName);
    _selectedColor = CategoryIntelligence.getColorForName(widget.initialName);

    _nameController.addListener(() {
      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        setState(() {
          _selectedIconKey = CategoryIntelligence.getIconKeyForName(name);
          _selectedColor = CategoryIntelligence.getColorForName(name);
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final userId = auth.user?.id;
    if (userId == null) return;

    final name = _nameController.text.trim();
    final db = ref.read(databaseProvider);

    // Case-insensitive duplicate check
    final existing = await (db.select(db.categories)
      ..where((t) => t.userId.equals(userId) | t.isSystemDefault.equals(true))
    ).get();

    final isDuplicate = existing.any((c) => 
      c.name.toLowerCase() == name.toLowerCase() && 
      c.type == widget.transactionType &&
      c.parentId == _selectedParentId
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A category named "$name" already exists.')),
      );
      return;
    }

    final newId = const Uuid().v4();
    final newCategory = Category(
      id: newId,
      userId: userId,
      name: name,
      type: widget.transactionType,
      parentId: _selectedParentId,
      icon: _selectedIconKey,
      color: '0x${_selectedColor.value.toRadixString(16).toUpperCase()}',
      isSystemDefault: false,
      createdAt: DateTime.now(),
      usageCount: 0,
    );

    try {
      await db.categoryDao.insertCategory(newCategory);
      ref.invalidate(categoriesProvider);

      if (mounted) {
        Navigator.pop(context, newCategory);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF0D121B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _selectedColor.withOpacity(0.3), width: 1.5),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _selectedColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _availableIcons.firstWhere((i) => i['key'] == _selectedIconKey, orElse: () => _availableIcons.last)['icon'],
              color: _selectedColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Create Category',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Name Field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _selectedColor, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.02),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Parent Category Selector
              categoriesAsync.when(
                data: (categories) {
                  final parentOptions = categories
                      .where((c) => c.type == widget.transactionType && c.parentId == null)
                      .toList();

                  return DropdownButtonFormField<String?>(
                    value: _selectedParentId,
                    dropdownColor: const Color(0xFF0F1A1C),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Parent Category (Optional)',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _selectedColor, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.02),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None (Make Parent Category)', style: TextStyle(color: Colors.white54)),
                      ),
                      ...parentOptions.map((c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.name),
                          )),
                    ],
                    onChanged: (value) => setState(() => _selectedParentId = value),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Icon Selector Header
              Text(
                'Select Icon',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Icon Grid
              SizedBox(
                height: 88,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final item = _availableIcons[index];
                    final isSelected = item['key'] == _selectedIconKey;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIconKey = item['key']),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? _selectedColor.withOpacity(0.2) : Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? _selectedColor : Colors.white12,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Icon(
                          item['icon'],
                          color: isSelected ? _selectedColor : Colors.white60,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Color Selector Header
              Text(
                'Select Accent Color',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Color List
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final color = _availableColors[index];
                    final isSelected = color.value == _selectedColor.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)]
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _saveCategory,
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
