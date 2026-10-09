import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/customer.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onDelete,
    this.displayBalance,
  });

  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final double? displayBalance;

  @override
  Widget build(BuildContext context) {
    final balance = displayBalance ?? customer.balance;
    final isPaid = balance <= 0.000001;
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFormatter.format(balance),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: balance > 0 ? AppColors.danger : AppColors.secondary,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'More options',
              onSelected: (_) => onDelete(),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'delete',
                  enabled: isPaid,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: isPaid ? AppColors.danger : null,
                      ),
                      const SizedBox(width: 10),
                      Text(isPaid ? 'Delete paid utang' : 'Pay balance first'),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }
}
