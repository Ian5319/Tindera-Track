import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/payment_record.dart';
import '../../providers/payment_provider.dart';
import '../../providers/utang_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/utang/payment_edit_dialog.dart';

class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({
    super.key,
    required this.customerId,
    this.customer,
  });

  final String customerId;
  final Customer? customer;

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  Customer? _customer;
  DateTime _paymentDate = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _requestId;
  String? _busyPaymentId;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final utang = context.read<UtangProvider>();
      final payments = context.read<PaymentProvider>();
      final customer = _customer ?? await utang.customer(widget.customerId);
      await payments.load();

      if (!mounted) return;

      setState(() {
        _customer = customer;
        _loading = false;
        _error = customer == null ? 'Customer not found.' : null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  double get _totalPaid {
    final customer = _customer;
    if (customer == null) return 0;
    return context.read<PaymentProvider>().totalPaymentsFor(customer.id);
  }

  double get _remainingBalance {
    final customer = _customer;
    if (customer == null) return 0;
    return math.max(0, customer.balance - _totalPaid).toDouble();
  }

  String get _status {
    if (_remainingBalance <= 0.000001) return 'PAID';
    if (_totalPaid > 0) return 'PARTIALLY PAID';
    return 'UNPAID';
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _requestId = null;
      _paymentDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _paymentDate.hour,
        _paymentDate.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    final customer = _customer;
    final amount = Validators.parseMoney(_amount.text);
    if (customer == null || amount == null) return;

    if (amount > _remainingBalance + 0.000001) {
      _showMessage('Payment cannot be greater than the remaining balance.');
      return;
    }

    setState(() => _saving = true);
    final requestId = _requestId ??=
        'p_${DateTime.now().microsecondsSinceEpoch}';

    try {
      await context.read<PaymentProvider>().recordPayment(
            customerId: customer.id,
            customerName: customer.name,
            amount: amount,
            paymentDate: _paymentDate,
            outstandingBalance: _remainingBalance,
            note: _note.text,
            requestId: requestId,
          );

      if (!mounted) return;
      _amount.clear();
      _note.clear();
      setState(() {
        _requestId = null;
        _saving = false;
      });
      _showMessage('Payment recorded successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(error.toString());
    }
  }

  Future<void> _editPayment(PaymentRecord payment) async {
    if (_busyPaymentId != null) return;

    final draft = await showPaymentEditDialog(context, payment);
    if (draft == null || !mounted) return;

    setState(() => _busyPaymentId = payment.id);
    try {
      await context.read<PaymentProvider>().updatePayment(
            payment: payment,
            amount: draft.amount,
            paymentDate: draft.paymentDate,
            note: draft.note,
          );
      if (mounted) _showMessage('Payment updated successfully.');
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busyPaymentId = null);
    }
  }

  Future<void> _deletePayment(PaymentRecord payment) async {
    if (_busyPaymentId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete payment?'),
        content: Text(
          'Delete ${currencyFormatter.format(payment.amount)} recorded on '
          '${shortDateFormatter.format(payment.paymentDate)}? This cannot be undone.',
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

    setState(() => _busyPaymentId = payment.id);
    try {
      await context.read<PaymentProvider>().deletePayment(payment.id);
      if (mounted) _showMessage('Payment deleted successfully.');
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busyPaymentId = null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final customer = _customer;
    if (customer == null || _error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Record Payment')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error ?? 'Customer not found.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: _load,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final paymentProvider = context.watch<PaymentProvider>();
    final payments = paymentProvider.paymentsForCustomer(customer.id);
    final remainingBalance = _remainingBalance;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Card(
              color: AppColors.warningBg,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SummaryRow('Original debt', customer.balance),
                    _SummaryRow('Total paid', _totalPaid),
                    _SummaryRow(
                      'Remaining balance',
                      remainingBalance,
                      emphasize: true,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_status),
                      backgroundColor: remainingBalance <= 0
                          ? AppColors.successBg
                          : AppColors.warningBg,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              validator: Validators.money,
              onChanged: (_) => setState(() => _requestId = null),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Payment amount',
                prefixText: '₱ ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Payment date'),
                subtitle: Text(dateFormatter.format(_paymentDate)),
                trailing: TextButton(
                  onPressed: _chooseDate,
                  child: const Text('Change'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLines: 2,
              onChanged: (_) => setState(() => _requestId = null),
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Add a payment note',
              ),
            ),
            const SizedBox(height: 22),
            CustomButton(
              label: 'Record Payment',
              icon: Icons.save_outlined,
              onPressed: remainingBalance <= 0 ? null : _save,
              loading: _saving,
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment history',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            if (payments.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No payments recorded yet.'),
                ),
              )
            else
              ...payments.map(
                (payment) => _PaymentRecordTile(
                  payment: payment,
                  busy: _busyPaymentId == payment.id,
                  onEdit: () => _editPayment(payment),
                  onDelete: () => _deletePayment(payment),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.amount, {this.emphasize = false});

  final String label;
  final double amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            currencyFormatter.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: emphasize ? AppColors.danger : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRecordTile extends StatelessWidget {
  const _PaymentRecordTile({
    required this.payment,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final PaymentRecord payment;
  final bool busy;
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
        trailing: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Wrap(
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
