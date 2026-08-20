import 'package:flutter/material.dart';

const Map<String, IconData> kIconCatalog = {
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'shopping_cart': Icons.shopping_cart,
  'receipt_long': Icons.receipt_long,
  'local_hospital': Icons.local_hospital,
  'shopping_bag': Icons.shopping_bag,
  'movie': Icons.movie,
  'category': Icons.category,
  'payments': Icons.payments,
  'card_giftcard': Icons.card_giftcard,
  'account_balance_wallet': Icons.account_balance_wallet,
  'account_balance': Icons.account_balance,
  'credit_card': Icons.credit_card,
  'savings': Icons.savings,
};

IconData iconForKey(String key) => kIconCatalog[key] ?? Icons.category;

const List<String> kAccountIconKeys = [
  'account_balance_wallet',
  'account_balance',
  'credit_card',
  'savings',
];

const List<String> kCategoryIconKeys = [
  'restaurant',
  'directions_car',
  'shopping_cart',
  'receipt_long',
  'local_hospital',
  'shopping_bag',
  'movie',
  'payments',
  'card_giftcard',
  'category',
];

const List<int> kColorPalette = [
  0xFFEF6C00,
  0xFF1E88E5,
  0xFF43A047,
  0xFF6D4C41,
  0xFFE53935,
  0xFF8E24AA,
  0xFFFB8C00,
  0xFF2E7D32,
  0xFFD81B60,
  0xFF757575,
];
