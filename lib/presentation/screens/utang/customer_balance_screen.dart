import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/utang_transaction.dart';
import '../../providers/utang_provider.dart';
import '../../widgets/utang/transaction_item.dart';

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
      final provider = context.read<UtangProvider>();
      final customer = await provider.customer(widget.customerId);

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

      final transactions = await provider.transactions(widget.customerId);

      if (!mounted) return;

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

  Future<void> _recordPayment(
    BuildContext context,
    Customer customer,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RecordPaymentSheet(customer: customer),
    );

    if (saved == true && mounted) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
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
                            currencyFormatter.format(customer.balance),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: AppColors.danger,
                            ),
                          ),
                          const Text(
                            'Total balance',
                            style: TextStyle(fontWeight: FontWeight.w700),
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
                    'Transaction history',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (_transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                      child: Text('No transactions yet.'),
                    ),
                  )
                else
                  ..._transactions.map(
                    (tx) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TransactionItem(transaction: tx),
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
            onPressed: customer.balance <= 0
                ? null
                : () => _recordPayment(context, customer),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Record Payment'),
          ),
        ),
      ),
    );
  }
}

class _RecordPaymentSheet extends StatefulWidget {
  const _RecordPaymentSheet({required this.customer});

  final Customer customer;

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = Validators.parseMoney(_controller.text);
    if (amount == null) {
      return;
    }

    if (amount > widget.customer.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment cannot be greater than the current balance.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final transaction = UtangTransaction(
        id: 't${DateTime.now().microsecondsSinceEpoch}',
        customerId: widget.customer.id,
        amount: amount,
        type: UtangType.payment,
        createdAt: DateTime.now(),
      );

      await context.read<UtangProvider>().addTransaction(transaction);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record Payment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Balance: ${currencyFormatter.format(widget.customer.balance)}',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              validator: Validators.money,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Payment amount',
                prefixText: '₱ ',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
