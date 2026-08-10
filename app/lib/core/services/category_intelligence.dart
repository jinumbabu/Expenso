import 'package:flutter/material.dart';

class CategoryIntelligence {
  static const Map<String, String> _iconMapping = {
    'food': 'fastfood',
    'restaurant': 'restaurant',
    'cafe': 'coffee',
    'snacks': 'fastfood',
    'fruits': 'spa',
    
    'travel': 'flight',
    'fuel': 'local_gas_station',
    'hotel': 'hotel',
    'flight': 'flight',
    'taxi': 'local_taxi',
    
    'shopping': 'shopping_bag',
    'grocery': 'shopping_cart',
    'amazon': 'shopping_bag',
    'flipkart': 'shopping_bag',
    'clothes': 'checkroom',
    
    'utilities': 'receipt_long',
    'electricity': 'electric_bolt',
    'water': 'water_drop',
    'recharge': 'phone_android',
    'mobile': 'phone_android',
    'internet': 'wifi',
    'wifi': 'wifi',
    'gas': 'local_fire_department',
    
    'entertainment': 'movie',
    'netflix': 'movie',
    'movie': 'movie',
    
    'salary': 'payments',
    'freelance': 'work',
    'investment': 'trending_up',
    'transfer': 'swap_horiz',
    'gift': 'card_giftcard',
    'rent': 'home',
    'medical': 'favorite',
    'education': 'school',
  };

  static const Map<String, String> _colorMapping = {
    'food': '0xFFFFA500',       // Orange
    'restaurant': '0xFFFFA500',
    'cafe': '0xFFFFA500',
    'snacks': '0xFFFFA500',
    'fruits': '0xFFFFA500',
    
    'travel': '0xFF0066FF',     // Blue
    'fuel': '0xFF0066FF',
    'hotel': '0xFF0066FF',
    'flight': '0xFF0066FF',
    'taxi': '0xFF0066FF',
    
    'shopping': '0xFF8A2BE2',   // Purple
    'grocery': '0xFF8A2BE2',
    'amazon': '0xFF8A2BE2',
    'flipkart': '0xFF8A2BE2',
    'clothes': '0xFF8A2BE2',
    
    'utilities': '0xFFFFB703',  // Amber/Yellow
    'electricity': '0xFFFFB703',
    'water': '0xFFFFB703',
    'recharge': '0xFFFFB703',
    'mobile': '0xFFFFB703',
    'internet': '0xFFFFB703',
    'wifi': '0xFFFFB703',
    'gas': '0xFFFFB703',
    
    'entertainment': '0xFFFF3B30', // Crimson/Red
    'netflix': '0xFFFF3B30',
    'movie': '0xFFFF3B30',
    
    'salary': '0xFF00FF88',      // Green
    'freelance': '0xFF00FF88',
    'investment': '0xFF00E5FF',   // Teal/Cyan
    'transfer': '0xFF6366F1',     // Indigo
    'gift': '0xFFEC4899',         // Pink
    'rent': '0xFF8B5CF6',         // Violet
    'medical': '0xFFEF4444',      // Red
    'education': '0xFF3B82F6',    // Blue
  };

  /// Returns the matching IconData for a given category name (case-insensitive keyword matching).
  static IconData getIconForName(String name) {
    final lowerName = name.toLowerCase();
    
    // Exact or contains match in our mappings
    for (var key in _iconMapping.keys) {
      if (lowerName.contains(key)) {
        return _getIconDataForString(_iconMapping[key]);
      }
    }
    
    return Icons.folder_outlined;
  }

  /// Returns the matching icon key string to be stored in the database.
  static String getIconKeyForName(String name) {
    final lowerName = name.toLowerCase();
    for (var key in _iconMapping.keys) {
      if (lowerName.contains(key)) {
        return _iconMapping[key]!;
      }
    }
    return 'folder';
  }

  /// Returns the matching Color for a given category name.
  static Color getColorForName(String name) {
    final hexString = getColorHexForName(name);
    return Color(int.parse(hexString));
  }

  /// Returns the matching hex string (e.g. '0xFFFFA500') to be stored in the database.
  static String getColorHexForName(String name) {
    final lowerName = name.toLowerCase();
    for (var key in _colorMapping.keys) {
      if (lowerName.contains(key)) {
        return _colorMapping[key]!;
      }
    }
    
    // Dynamic color hash fallback based on the category name
    final hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    final fallbackColors = [
      '0xFFFFA500', // Orange
      '0xFF0066FF', // Blue
      '0xFF8A2BE2', // Purple
      '0xFFFFB703', // Yellow
      '0xFFFF3B30', // Red
      '0xFF00FF88', // Green
      '0xFF00E5FF', // Cyan
      '0xFFEC4899', // Pink
    ];
    return fallbackColors[hash % fallbackColors.length];
  }

  static IconData _getIconDataForString(String? key) {
    if (key == null) return Icons.folder_outlined;
    switch (key) {
      case 'fastfood':
        return Icons.fastfood_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'coffee':
        return Icons.coffee_outlined;
      case 'spa':
        return Icons.spa_outlined;
      case 'flight':
        return Icons.flight_outlined;
      case 'local_gas_station':
        return Icons.local_gas_station_outlined;
      case 'hotel':
        return Icons.hotel_outlined;
      case 'local_taxi':
        return Icons.local_taxi_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'checkroom':
        return Icons.checkroom_outlined;
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'electric_bolt':
        return Icons.electric_bolt_outlined;
      case 'water_drop':
        return Icons.water_drop_outlined;
      case 'phone_android':
        return Icons.phone_android_outlined;
      case 'wifi':
        return Icons.wifi_outlined;
      case 'local_fire_department':
        return Icons.local_fire_department_outlined;
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
      case 'card_giftcard':
        return Icons.card_giftcard_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'favorite':
        return Icons.favorite_outlined;
      case 'school':
        return Icons.school_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}
