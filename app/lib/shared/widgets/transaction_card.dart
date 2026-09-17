import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/category_intelligence.dart';
import '../../features/accounts/presentation/providers/account_formatters.dart';
import 'privacy_text.dart';

/// Reusable transaction card widget with exact 3-line layout:
/// LINE 1: [LOGO]  (SMS • ) TITLE / DESCRIPTION               AMOUNT
/// LINE 2:         MAIN CATEGORY > SUB CATEGORY
/// LINE 3:         TIME • FINANCIAL ACCOUNT • PAYMENT METHOD
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

  String? _getMeaningful(String? val) {
    if (val == null) return null;
    final trimmed = val.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase() == 'null' ||
        trimmed.toLowerCase() == 'none' ||
        trimmed.toLowerCase() == 'uncategorized') {
      return null;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer_debit' || transaction.type == 'transfer_credit';

    // 1. Logo color & icon logic
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

    IconData catIcon = Icons.category_outlined;
    if (isTransfer) {
      catIcon = Icons.swap_horiz;
    } else if (category != null) {
      catIcon = CategoryIntelligence.getIconForName(category!.name);
    }

    // 2. SMS Source Detection
    final isSms = transaction.source.toLowerCase().contains('sms') ||
        (transaction.supportingSms != null && transaction.supportingSms!.trim().isNotEmpty);

    // 3. Title Selection Hierarchy: Details -> SMS Alert -> Subcategory -> Main Category -> "Transaction"
    final meaningfulMerchant = _getMeaningful(transaction.merchant);
    final meaningfulDesc = _getMeaningful(transaction.description);
    final meaningfulSubCat = _getMeaningful(subcategory?.name);
    final meaningfulMainCat = _getMeaningful(category?.name);

    final titleCandidate = meaningfulMerchant ??
        meaningfulDesc ??
        meaningfulSubCat ??
        meaningfulMainCat ??
        'Transaction';

    // 4. Line 1: Amount sign and color
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

    // 5. Line 2: Main Category > Sub Category
    String categoryText;
    final mainCatName = _getMeaningful(category?.name);
    final subCatName = _getMeaningful(subcategory?.name);

    if (mainCatName != null) {
      if (subCatName != null && subCatName != mainCatName) {
        categoryText = '$mainCatName > $subCatName';
      } else {
        categoryText = mainCatName;
      }
    } else if (subCatName != null) {
      categoryText = subCatName;
    } else if (isTransfer) {
      categoryText = 'Transfer';
    } else {
      categoryText = 'Uncategorized';
    }

    // 6. Line 3: Time • Financial Account • Payment Method
    final timeStr = DateFormat('hh:mm a').format(transaction.date);

    String? accStr;
    if (account != null) {
      final title = account!.displayTitle.trim();
      if (title.isNotEmpty && title != 'null') {
        accStr = title;
      }
    }

    String? pmStr;
    if (paymentMethod != null) {
      final name = paymentMethod!.name.trim();
      if (name.isNotEmpty && name != 'null') {
        if (name.toLowerCase().startsWith('via ')) {
          pmStr = name;
        } else {
          pmStr = 'via $name';
        }
      }
    }

    final line3Parts = <String>[
      timeStr,
      if (accStr != null) accStr,
      if (pmStr != null) pmStr,
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
                      // Line 1: (SMS • ) Title / Description & Amount
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  if (isSms) ...[
                                    const TextSpan(
                                      text: 'SMS',
                                      style: TextStyle(
                                        color: Color(0xFF00E5FF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' • ',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                  TextSpan(
                                    text: titleCandidate,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ],
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
