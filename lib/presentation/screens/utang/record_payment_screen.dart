import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/customer.dart';
import '../../providers/payment_provider.dart';
import '../../providers/utang_provider.dart';
import '../../widgets/common/custom_button.dart';

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
      final customer = _customer ??
          await utang.customer(widget.customerId);
      await payments.load();

      if (!mounted) return;

      setState(() {
        _customer = customer;
        _loading = false;
        _error = customer == null
            ? 'Customer not found.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  double get _remainingBalance {
    final customer = _customer;
    if (customer == null) return 0;

    final recordedPayments =
        context.read<PaymentProvider>().totalPaymentsFor(customer.id);
    return math.max(0, customer.balance - recordedPayments).toDouble();
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final customer = _customer;
    final amount = Validators.parseMoney(_amount.text);
    if (customer == null || amount == null) return;

    if (amount > _remainingBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment cannot be greater than the remaining balance.',
          ),
        ),
      );
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

      _requestId = null;
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                child: Row(
                  children: [
                    Expanded(
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
                          const SizedBox(height: 6),
                          const Text(
                            'Remaining balance',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormatter.format(remainingBalance),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.warningText,
                      size: 34,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              validator: Validators.money,
              onChanged: (_) => _requestId = null,
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
              onChanged: (_) => _requestId = null,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Add a payment note',
              ),
            ),
            const SizedBox(height: 22),
            CustomButton(
              label: 'Save Payment',
              icon: Icons.save_outlined,
              onPressed: remainingBalance <= 0 ? null : _save,
              loading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
