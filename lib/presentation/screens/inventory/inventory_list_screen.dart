import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/inventory/product_list_tile.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});
  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final items = provider.items.where((p) => p.name.toLowerCase().contains(_query.toLowerCase().trim())).toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/inventory/add'), icon: const Icon(Icons.add), label: const Text('Add item')),
      body: provider.loading && provider.items.isEmpty ? const LoadingIndicator(message: 'Loading inventory…') : provider.error != null ? AppErrorWidget(message: provider.error!, onRetry: provider.load) : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
        Text('Inventory', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('${provider.items.length} tracked products', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 18),
        TextField(onChanged: (value) => setState(() => _query = value), decoration: const InputDecoration(labelText: 'Search products', prefixIcon: Icon(Icons.search), suffixIcon: Icon(Icons.tune))),
        const SizedBox(height: 14),
        if (items.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.search_off, size: 48), const SizedBox(height: 8), Text('No products match “$_query”.')]))
        else ...items.map((product) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ProductListTile(product: product, onTap: () => context.push('/inventory/add', extra: product)))),
        if (provider.lowStockItems.isNotEmpty) Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(16)), child: Text('${provider.lowStockItems.length} low-stock item(s) are at or below their threshold.', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warningText))),
      ]),
    );
  }
}
