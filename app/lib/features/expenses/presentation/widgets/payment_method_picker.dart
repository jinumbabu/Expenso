import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/expense_provider.dart';

class PaymentMethodPicker extends ConsumerWidget {
  final String? selectedPaymentMethodId;
  final ValueChanged<PaymentMethod> onPaymentMethodSelected;
  final String? accountType;

  const PaymentMethodPicker({
    super.key,
    required this.selectedPaymentMethodId,
    required this.onPaymentMethodSelected,
    this.accountType,
  });

  IconData _getPaymentMethodIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.account_balance_wallet_outlined;
      case 'upi':
        return Icons.mobile_friendly;
      case 'card':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance;
      case 'wallet':
        return Icons.wallet_outlined;
      case 'loan':
        return Icons.monetization_on_outlined;
      case 'investment':
        return Icons.trending_up_rounded;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentMethodColor(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return const Color(0xFF00E5FF); // Cyan
      case 'upi':
        return const Color(0xFF0066FF); // Blue
      case 'card':
        return const Color(0xFFFF3B30); // Red
      case 'bank':
        return Colors.teal;
      case 'wallet':
        return const Color(0xFFFFB703); // Yellow/Orange
      case 'loan':
        return Colors.amber;
      case 'investment':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return methodsAsync.when(
      data: (methods) {
        var filteredMethods = methods;
        if (accountType != null) {
          final type = accountType!.toLowerCase();
          if (type == 'cash') {
            filteredMethods = methods.where((pm) => pm.name.toLowerCase() == 'cash').toList();
          } else if (type == 'savings' || type == 'current') {
            filteredMethods = methods.where((pm) {
              final name = pm.name.toLowerCase();
              return name == 'upi' || name == 'debit card' || name == 'debit_card' || name == 'net banking' || name == 'net_banking';
            }).toList();
          } else if (type == 'credit_card') {
            filteredMethods = methods.where((pm) {
              final name = pm.name.toLowerCase();
              return name == 'credit card' || name == 'credit_card' || name == 'upi' || name == 'net banking' || name == 'net_banking';
            }).toList();
          } else if (type == 'wallet') {
            filteredMethods = methods.where((pm) {
              final name = pm.name.toLowerCase();
              return name == 'wallet balance' || name == 'wallet_balance' || name == 'upi';
            }).toList();
          } else if (type == 'loan' || type == 'loan_account') {
            filteredMethods = methods.where((pm) {
              final name = pm.name.toLowerCase();
              return name == 'loan disbursement' || name == 'loan_disbursement' || name == 'emi payment' || name == 'emi_payment';
            }).toList();
          } else if (type == 'investment') {
            filteredMethods = methods.where((pm) {
              final name = pm.name.toLowerCase();
              return name == 'buy' || name == 'sell' || name == 'transfer';
            }).toList();
          }
        }

        if (filteredMethods.isEmpty) {
          return const Center(
            child: Text(
              'No payment methods found',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filteredMethods.map((method) {
            final isSelected = method.id == selectedPaymentMethodId;
            final color = _getPaymentMethodColor(method.type);
            final icon = _getPaymentMethodIcon(method.type);

            return ChoiceChip(
              avatar: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 16,
              ),
              label: Text(
                method.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onPaymentMethodSelected(method);
                }
              },
              selectedColor: color.withOpacity(0.4),
              backgroundColor: Colors.white.withOpacity(0.03),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? color : Colors.white12,
                ),
              ),
            );
          }).toList(),
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
