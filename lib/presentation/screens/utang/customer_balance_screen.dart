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

class _CustomerBalanceScreenState
    extends State<CustomerBalanceScreen> {
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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final provider = context.read<UtangProvider>();

      final customer =
          await provider.customer(widget.customerId);

      if (customer == null) {
        if (!mounted) return;

        setState(() {
          _customer = null;
          _transactions = [];
          _loading = false;
          _error = 'Customer not found.';
        });

        return;
      }

      final transactions =
          await provider.transactions(widget.customerId);

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
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom:
              MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Payment',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Balance: ${currencyFormatter.format(customer.balance)}',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                validator: Validators.money,
                keyboardType:
                    const TextInputType.numberWithOptions(
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
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ??
                        false)) {
                      return;
                    }

                    final amount = double.parse(
                      controller.text.replaceAll(',', ''),
                    );

                    if (amount > customer.balance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Payment cannot be greater than the current balance.',
                          ),
                        ),
                      );
                      return;
                    }

                    await context
                        .read<UtangProvider>()
                        .addTransaction(
                          UtangTransaction(
                            id:
                                't${DateTime.now().microsecondsSinceEpoch}',
                            customerId: customer.id,
                            amount: amount,
                            type: UtangType.payment,
                            createdAt: DateTime.now(),
                          ),
                        );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    controller.dispose();

    if (mounted) {
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
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              10,
            ),
            child: Card(
              color: AppColors.secondary.withValues(alpha: .10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(customer.phone),
                          const SizedBox(height: 14),
                          Text(
                            currencyFormatter.format(
                              customer.balance,
                            ),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: AppColors.danger,
                            ),
                          ),
                          const Text(
                            'Total balance',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
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
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                110,
              ),
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
                      padding:
                          const EdgeInsets.only(bottom: 8),
                      child: TransactionItem(
                        transaction: tx,
                      ),
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
                : () => _recordPayment(
                      context,
                      customer,
                    ),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Record Payment'),
          ),
        ),
      ),
    );
  }
}