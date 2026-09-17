import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/utang_transaction.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({super.key, required this.transaction});
  final UtangTransaction transaction;
  @override
  Widget build(BuildContext context) {
    final credit = transaction.type == UtangType.credit;
    return Card(child: ListTile(leading: CircleAvatar(backgroundColor: credit ? AppColors.warningBg : AppColors.successBg, child: Icon(credit ? Icons.add : Icons.remove, color: credit ? AppColors.warningText : AppColors.secondary)), title: Text(credit ? 'Charge' : 'Payment', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${dateFormatter.format(transaction.createdAt)}${transaction.note == null ? '' : '\n${transaction.note}'}'), isThreeLine: transaction.note != null, trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (transaction.photoUrl != null && File(transaction.photoUrl!).existsSync()) const Icon(Icons.photo_camera_outlined, size: 18), const SizedBox(width: 8), Text('${credit ? '+' : '-'}${currencyFormatter.format(transaction.amount)}', style: TextStyle(fontWeight: FontWeight.w800, color: credit ? AppColors.warningText : AppColors.secondary))])));
  }
}
