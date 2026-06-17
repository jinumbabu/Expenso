import 'package:flutter/material.dart';

class IconMapper {
  static IconData getIcon(String? iconName) {
    if (iconName == null) return Icons.category;
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'payments':
        return Icons.payments;
      case 'work':
        return Icons.work;
      case 'trending_up':
        return Icons.trending_up;
      case 'swap_horiz':
        return Icons.swap_horiz;
      default:
        return Icons.category;
    }
  }

  static Color getColor(String? iconName) {
    if (iconName == null) return Colors.teal;
    switch (iconName) {
      case 'fastfood':
        return Colors.orange;
      case 'local_gas_station':
        return Colors.blue;
      case 'shopping_cart':
        return Colors.green;
      case 'receipt_long':
        return Colors.red;
      case 'shopping_bag':
        return Colors.purple;
      case 'movie':
        return Colors.pink;
      case 'payments':
        return Colors.green;
      case 'work':
        return Colors.cyan;
      case 'trending_up':
        return Colors.amber;
      case 'swap_horiz':
        return Colors.indigo;
      default:
        return Colors.teal;
    }
  }
}
