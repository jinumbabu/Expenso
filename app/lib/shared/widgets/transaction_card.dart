import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/category_intelligence.dart';
import '../../features/accounts/presentation/providers/account_formatters.dart';
import 'privacy_text.dart';

/// Reusable transaction card widget with exact 3-line layout:
/// Line 1: [LOGO] Title / Description                      AMOUNT
/// Line 2: Main Category > Sub Category
/// Line 3: 04:41 PM • HDFC 3726 • via UPI
class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final Category? subcategory;
  final Account? account;
  final PaymentMethod? paymentMethod;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.category,
    this.subcategory,
    this.account,
    this.paymentMethod,
    this.onTap,
  });

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer_debit' || transaction.type == 'transfer_credit';

    // Logo color logic
    Color catColor = const Color(0xFF0066FF);
    if (isTransfer) {
      catColor = const Color(0xFFFFB703);
    } else if (category != null) {
      if (category!.color != null && category!.color!.isNotEmpty) {
        try {
          catColor = Color(int.parse(category!.color!));
        } catch (_) {}
      } else {
        catColor = CategoryIntelligence.getColorForName(category!.name);
      }
    }

    // Logo icon logic
    IconData catIcon = Icons.category_outlined;
    if (isTransfer) {
      catIcon = Icons.swap_horiz;
    } else if (category != null) {
      catIcon = CategoryIntelligence.getIconForName(category!.name);
    }

    // Line 1: Title / Description
    String title = transaction.description ?? transaction.merchant ?? subcategory?.name ?? category?.name ?? 'Uncategorized';
    if (title.trim().isEmpty) {
      title = subcategory?.name ?? category?.name ?? 'Uncategorized';
    }

    // Line 1: Amount sign and color
    Color amountColor = const Color(0xFFFF3B30); // Expense -> Red
    String sign = '-';
    if (isIncome || transaction.type == 'transfer_credit') {
      amountColor = const Color(0xFF00E5FF); // Income -> Cyan/Blue
      sign = '+';
    } else if (transaction.type == 'transfer_debit') {
      amountColor = const Color(0xFFFFB703); // Transfer debit -> Amber
      sign = '-';
    }

    final amountRawValue = sign + _formatMoney(transaction.amount);

    // Line 2: Main Category > Sub Category
    String categoryText;
    if (category != null) {
      if (subcategory != null && subcategory!.name.isNotEmpty) {
        categoryText = '${category!.name} > ${subcategory!.name}';
      } else {
        categoryText = category!.name;
      }
    } else if (subcategory != null && subcategory!.name.isNotEmpty) {
      categoryText = subcategory!.name;
    } else if (isTransfer) {
      categoryText = 'Transfer';
    } else {
      categoryText = 'Uncategorized';
    }

    // Line 3: Time • Account • Payment Method
    final timeStr = DateFormat('hh:mm a').format(transaction.date);

    String? accStr;
    if (account != null) {
      accStr = account!.displayTitle;
    }

    String? pmStr;
    if (paymentMethod != null && paymentMethod!.name.isNotEmpty) {
      final name = paymentMethod!.name;
      if (name.toLowerCase().startsWith('via ')) {
        pmStr = name;
      } else {
        pmStr = 'via $name';
      }
    }

    final line3Parts = <String>[
      timeStr,
      if (accStr != null && accStr.isNotEmpty) accStr,
      if (pmStr != null && pmStr.isNotEmpty) pmStr,
    ];
    final line3Text = line3Parts.join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(
              children: [
                // Logo Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(catIcon, color: catColor, size: 20),
                ),
                const SizedBox(width: 12),

                // 3 Lines content column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Line 1: Title / Description & Amount
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PrivacyText(
                            rawValue: amountRawValue,
                            isTransactionAmount: true,
                            style: TextStyle(
                              color: amountColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Line 2: Main Category > Sub Category
                      Text(
                        categoryText,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Line 3: Time • Account • Payment Method
                      Text(
                        line3Text,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
