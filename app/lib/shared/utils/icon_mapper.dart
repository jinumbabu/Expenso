import 'package:flutter/material.dart';

class IconMapper {
  static IconData getIcon(String? iconName) {
    if (iconName == null) return Icons.category_outlined;
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood_outlined;
      case 'local_gas_station':
        return Icons.local_gas_station_outlined;
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'movie':
        return Icons.movie_outlined;
      case 'payments':
        return Icons.payments_outlined;
      case 'work':
        return Icons.work_outline;
      case 'trending_up':
        return Icons.trending_up_outlined;
      case 'swap_horiz':
        return Icons.swap_horiz_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  static Color getColor(String? iconName) {
    if (iconName == null) return const Color(0xFF0066FF);
    switch (iconName) {
      case 'fastfood':
        return Colors.orange;
      case 'local_gas_station':
        return const Color(0xFF0066FF); // Electric blue
      case 'shopping_cart':
        return const Color(0xFF00E5FF); // Bright neon cyan instead of green
      case 'receipt_long':
        return Colors.redAccent;
      case 'shopping_bag':
        return Colors.purpleAccent;
      case 'movie':
        return Colors.pinkAccent;
      case 'payments':
        return const Color(0xFF0066FF); // Electric blue instead of green
      case 'work':
        return Colors.cyanAccent;
      case 'trending_up':
        return Colors.amberAccent;
      case 'swap_horiz':
        return Colors.indigoAccent;
      default:
        return const Color(0xFF0066FF);
    }
  }
}

