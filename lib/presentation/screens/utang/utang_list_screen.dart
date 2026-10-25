import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/customer.dart';
import '../../providers/payment_provider.dart';
import '../../providers/utang_provider.dart';
import '../../widgets/utang/customer_card.dart';

class UtangListScreen extends StatefulWidget {
  const UtangListScreen({super.key});

  @override
  State<UtangListScreen> createState() => _UtangListScreenState();
}

class _UtangListScreenState extends State<UtangListScreen> {
  String _query = '';

  Future<void> _deletePaidCustomer(
    BuildContext context,
    Customer customer,
    double remainingBalance,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete paid Utang?'),
        content: Text(
          'Remove ${customer.name} from the Utang list? Their transaction and payment history will be kept for reports.',
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

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<UtangProvider>().deletePaidCustomer(
            customerId: customer.id,
            remainingBalance: remainingBalance,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paid Utang deleted successfully.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UtangProvider>();
    final payments = context.watch<PaymentProvider>();
    final outstanding = payments.remainingOutstanding(provider.customers);
    final normalizedQuery = _query.trim().toLowerCase();
    final customers = provider.customers.where((customer) {
      if (normalizedQuery.isEmpty) return true;
      return customer.name.toLowerCase().contains(normalizedQuery) ||
          customer.phone.toLowerCase().contains(normalizedQuery);
    }).toList();
    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/utang/record'),
            icon: const Icon(Icons.add),
            label: const Text('Record utang')),
        body: RefreshIndicator(
            onRefresh: () async {
              await provider.load();
              await payments.load();
            },
            child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  Text('Utang',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                      'Outstanding balance: ${currencyFormatter.format(outstanding)}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      labelText: 'Search customers',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (provider.error != null)
                    Card(
                      color: AppColors.warningBg,
                      child: ListTile(
                        leading: const Icon(Icons.cloud_off_outlined),
                        title: Text(provider.error!),
                        trailing: TextButton(
                          onPressed: provider.load,
                          child: const Text('Retry'),
                        ),
                      ),
                    ),
                  if (provider.loading && provider.customers.isEmpty)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator()))
                  else if (customers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          const Icon(Icons.person_search_outlined, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            normalizedQuery.isEmpty
                                ? 'No Utang customers yet.'
                                : 'No customers match “$_query”.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...customers.map((customer) {
                      final remainingBalance = payments.remainingForCustomer(
                        customerId: customer.id,
                        utangBalance: customer.balance,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CustomerCard(
                          customer: customer,
                          displayBalance: remainingBalance,
                          onTap: () =>
                              context.push('/utang/customer/${customer.id}'),
                          onDelete: () => _deletePaidCustomer(
                            context,
                            customer,
                            remainingBalance,
                          ),
                        ),
                      );
                    }),
                ])));
  }
}
