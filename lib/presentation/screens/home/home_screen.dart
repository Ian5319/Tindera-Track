import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/utang_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final inventory = context.watch<InventoryProvider>();
    final utang = context.watch<UtangProvider>();
    const todaysSales = 4865.00;

    return RefreshIndicator(onRefresh: () async { await inventory.load(); await utang.load(); }, child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 28), children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hello, ${user?.name.split(' ').first ?? 'Store Owner'} 👋', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(user?.storeName ?? 'Your store', style: Theme.of(context).textTheme.bodyLarge)])), PopupMenuButton<String>(onSelected: (value) async { if (value == 'logout') { await context.read<AuthProvider>().logout(); if (context.mounted) context.go('/login'); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'logout', child: Text('Log out'))], child: const CircleAvatar(child: Icon(Icons.person_outline)))]),
      const SizedBox(height: 24),
      _MetricCard(title: "Today's Sales", value: currencyFormatter.format(todaysSales), icon: Icons.point_of_sale_outlined),
      const SizedBox(height: 14),
      _MetricCard(title: 'Low Stock Alerts', value: '${inventory.lowStockItems.length} items need attention', icon: Icons.warning_amber_rounded, warning: inventory.lowStockItems.isNotEmpty, onTap: () => context.go('/inventory')),
      const SizedBox(height: 14),
      _MetricCard(title: 'Outstanding Utang', value: currencyFormatter.format(utang.outstanding), icon: Icons.receipt_long_outlined, warning: utang.outstanding > 0, onTap: () => context.go('/utang')),
      const SizedBox(height: 24),
      const Text('Quick actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: _ActionCard(icon: Icons.add_box_outlined, label: 'Add item', onTap: () => context.push('/inventory/add'))), const SizedBox(width: 12), Expanded(child: _ActionCard(icon: Icons.camera_alt_outlined, label: 'Record utang', onTap: () => context.push('/utang/record')))]),
    ]));
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.icon, this.warning = false, this.onTap});
  final String title, value; final IconData icon; final bool warning; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(color: warning ? AppColors.warningBg : Colors.white, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: warning ? AppColors.accent.withValues( alpha: .25) : AppColors.cream, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: warning ? AppColors.warningText : AppColors.primaryDark)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))])), if (onTap != null) const Icon(Icons.chevron_right)]))));
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [Icon(icon, size: 34, color: AppColors.primary), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))]))));
}
