import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/payment_record.dart';

class PaymentEditDraft {
  const PaymentEditDraft({
    required this.amount,
    required this.paymentDate,
    required this.note,
  });

  final double amount;
  final DateTime paymentDate;
  final String? note;
}

Future<PaymentEditDraft?> showPaymentEditDialog(
  BuildContext context,
  PaymentRecord payment,
) async {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController(
    text: payment.amount.toStringAsFixed(2),
  );
  final noteController = TextEditingController(text: payment.note ?? '');
  var paymentDate = payment.paymentDate;

  final result = await showDialog<PaymentEditDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Edit payment'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  autofocus: true,
                  validator: Validators.money,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Payment amount',
                    prefixText: '₱ ',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Payment date'),
                  subtitle: Text(dateFormatter.format(paymentDate)),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: dialogContext,
                      initialDate: paymentDate.isAfter(DateTime.now())
                          ? DateTime.now()
                          : paymentDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (selected == null) return;
                    setState(() {
                      paymentDate = DateTime(
                        selected.year,
                        selected.month,
                        selected.day,
                        paymentDate.hour,
                        paymentDate.minute,
                      );
                    });
                  },
                ),
                TextFormField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.of(dialogContext).pop(
                PaymentEditDraft(
                  amount: Validators.parseMoney(amountController.text)!,
                  paymentDate: paymentDate,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                ),
              );
            },
            child: const Text('Save changes'),
          ),
        ],
      ),
    ),
  );

  amountController.dispose();
  noteController.dispose();
  return result;
}
