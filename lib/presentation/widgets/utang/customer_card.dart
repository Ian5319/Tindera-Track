import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/customer.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    this.displayBalance,
  });

  final Customer customer;
  final VoidCallback onTap;
  final double? displayBalance;

  @override
  Widget build(BuildContext context) {
    final balance = displayBalance ?? customer.balance;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withValues(alpha: .12),
          child: const Icon(
            Icons.person_outline,
            color: AppColors.secondary,
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(customer.phone),
        trailing: Text(
          currencyFormatter.format(balance),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: balance > 0 ? AppColors.danger : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
