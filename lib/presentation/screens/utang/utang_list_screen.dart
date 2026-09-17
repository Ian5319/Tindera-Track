import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/utang_provider.dart';
import '../../widgets/utang/customer_card.dart';

class UtangListScreen extends StatelessWidget {
  const UtangListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UtangProvider>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/utang/record'), icon: const Icon(Icons.add), label: const Text('Record utang')),
      body: RefreshIndicator(onRefresh: provider.load, child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
        Text('Utang', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('Outstanding balance: ${currencyFormatter.format(provider.outstanding)}', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        if (provider.loading && provider.customers.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
        else ...provider.customers.map((customer) => Padding(padding: const EdgeInsets.only(bottom: 10), child: CustomerCard(customer: customer, onTap: () => context.push('/utang/customer/${customer.id}')))),
      ])));
  }
}
