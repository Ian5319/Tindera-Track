import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/customer.dart';
import '../../providers/payment_provider.dart';
import '../../providers/utang_provider.dart';
import '../../widgets/utang/customer_card.dart';

class UtangListScreen extends StatelessWidget {
  const UtangListScreen({super.key});

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
    final outstanding = provider.customers.fold<double>(
      0,
      (total, customer) => total + payments.remainingForCustomer(
        customerId: customer.id,
        utangBalance: customer.balance,
      ),
    );
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/utang/record'), icon: const Icon(Icons.add), label: const Text('Record utang')),
      body: RefreshIndicator(onRefresh: () async { await provider.load(); await payments.load(); }, child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
        Text('Utang', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('Outstanding balance: ${currencyFormatter.format(outstanding)}', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        if (provider.loading && provider.customers.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
        else ...provider.customers.map((customer) {
          final remainingBalance = payments.remainingForCustomer(
            customerId: customer.id,
            utangBalance: customer.balance,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CustomerCard(
              customer: customer,
              displayBalance: remainingBalance,
              onTap: () => context.push('/utang/customer/${customer.id}'),
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
