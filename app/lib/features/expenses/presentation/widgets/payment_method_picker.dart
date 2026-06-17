import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/expense_provider.dart';

class PaymentMethodPicker extends ConsumerWidget {
  final String? selectedPaymentMethodId;
  final ValueChanged<PaymentMethod> onPaymentMethodSelected;

  const PaymentMethodPicker({
    super.key,
    required this.selectedPaymentMethodId,
    required this.onPaymentMethodSelected,
  });

  IconData _getPaymentMethodIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'upi':
        return Icons.mobile_friendly;
      case 'card':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentMethodColor(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'upi':
        return Colors.blue;
      case 'card':
        return Colors.purple;
      case 'bank':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return methodsAsync.when(
      data: (methods) {
        if (methods.isEmpty) {
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
          children: methods.map((method) {
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
              selectedColor: color,
              backgroundColor: Colors.white.withOpacity(0.05),
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
