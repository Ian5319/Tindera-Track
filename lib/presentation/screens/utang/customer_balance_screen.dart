import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/payment_record.dart';
import '../../../data/models/utang_transaction.dart';
import '../../providers/payment_provider.dart';
import '../../providers/utang_provider.dart';
import '../../widgets/utang/transaction_item.dart';
import '../../widgets/utang/payment_edit_dialog.dart';

class CustomerBalanceScreen extends StatefulWidget {
  const CustomerBalanceScreen({
    super.key,
    required this.customerId,
  });

  final String customerId;

  @override
  State<CustomerBalanceScreen> createState() =>
      _CustomerBalanceScreenState();
}

class _CustomerBalanceScreenState extends State<CustomerBalanceScreen> {
  Customer? _customer;
  List<UtangTransaction> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final utang = context.read<UtangProvider>();
      final payments = context.read<PaymentProvider>();
      final customerFuture = utang.customer(widget.customerId);
      final transactionsFuture = utang.transactions(widget.customerId);

      await payments.load();
      final customer = await customerFuture;
      final transactions = await transactionsFuture;

      if (!mounted) return;

      if (customer == null) {
        setState(() {
          _customer = null;
          _transactions = [];
          _loading = false;
          _error = 'Customer not found.';
        });
        return;
      }

      setState(() {
        _customer = customer;
        _transactions = transactions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to load customer history.';
      });
    }
  }

  Future<void> _recordPayment(Customer customer) async {
    final saved = await context.push<bool>(
      '/utang/customer/${customer.id}/payment',
      extra: customer,
    );

    if (saved == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _editPayment(PaymentRecord payment) async {
    final draft = await showPaymentEditDialog(context, payment);
    if (draft == null || !mounted) return;

    try {
      await context.read<PaymentProvider>().updatePayment(
            payment: payment,
            amount: draft.amount,
            paymentDate: draft.paymentDate,
            note: draft.note,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment updated successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _deletePayment(PaymentRecord payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete payment?'),
        content: Text(
          'Delete ${currencyFormatter.format(payment.amount)}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<PaymentProvider>().deletePayment(payment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment deleted successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Customer Balance / History'),
        ),
        body: Center(
          child: Text(_error ?? 'Customer not found.'),
        ),
      );
    }

    final customer = _customer!;
    final paymentProvider = context.watch<PaymentProvider>();
    final paymentError = paymentProvider.error;
    final totalPayments = paymentProvider.totalPaymentsFor(customer.id);
    final payments = paymentProvider.paymentsForCustomer(customer.id);
    final remainingBalance =
        math.max(0, customer.balance - totalPayments).toDouble();
    final status = remainingBalance <= 0.000001
        ? 'PAID'
        : totalPayments > 0
            ? 'PARTIALLY PAID'
            : 'UNPAID';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Balance / History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Card(
              color: AppColors.secondary.withValues(alpha: .10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(customer.phone),
                          const SizedBox(height: 14),
                          Text(
                            currencyFormatter.format(remainingBalance),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: AppColors.danger,
                            ),
                          ),
                          const Text(
                            'Remaining balance',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text('Total paid: ${currencyFormatter.format(totalPayments)}'),
                          const SizedBox(height: 4),
                          Text(
                            'Status: $status',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 44,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Utang transaction history',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (_transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('No Utang transactions yet.')),
                  )
                else
                  ..._transactions.map(
                    (tx) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TransactionItem(transaction: tx),
                    ),
                  ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Payment history',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (paymentError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      paymentError,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  )
                else if (payments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('No payments recorded yet.')),
                  )
                else
                  ...payments.map(
                    (payment) => _PaymentRecordTile(
                      payment,
                      onEdit: () => _editPayment(payment),
                      onDelete: () => _deletePayment(payment),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: Colors.black12,
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: remainingBalance <= 0
                ? null
                : () => _recordPayment(customer),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Record Payment'),
          ),
        ),
      ),
    );
  }
}

class _PaymentRecordTile extends StatelessWidget {
  const _PaymentRecordTile(
    this.payment, {
    required this.onEdit,
    required this.onDelete,
  });

  final PaymentRecord payment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.successBg,
          child: Icon(
            Icons.payments_outlined,
            color: AppColors.secondary,
          ),
        ),
        title: Text(
          currencyFormatter.format(payment.amount),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.secondary,
          ),
        ),
        subtitle: Text(
          '${dateFormatter.format(payment.paymentDate)}${payment.note == null ? '' : '\n${payment.note}'}',
        ),
        isThreeLine: payment.note != null,
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: 'Edit payment',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete payment',
              onPressed: onDelete,
              color: AppColors.danger,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
