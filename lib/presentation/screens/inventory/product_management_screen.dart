import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../providers/inventory_provider.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({
    super.key,
    required this.productId,
    this.product,
  });

  final String productId;
  final Product? product;

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InventoryProvider>().loadSales();
    });
  }

  Product? get _product {
    final provider = context.read<InventoryProvider>();
    return provider.find(widget.productId) ?? widget.product;
  }

  Future<void> _adjustStock({required bool add}) async {
    final product = _product;
    if (product == null) return;

    final quantity = await _askQuantity(
      title: add ? 'Add stock' : 'Remove stock',
      action: add ? 'Add' : 'Remove',
    );
    if (quantity == null || !mounted) return;

    // Let the quantity dialog finish removing its overlay before the
    // inventory provider starts rebuilding the underlying page.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    try {
      final provider = context.read<InventoryProvider>();
      if (add) {
        await provider.addStock(product.id, quantity);
      } else {
        await provider.removeStock(product.id, quantity);
      }
      if (mounted) {
        _showMessage(add ? 'Stock added successfully.' : 'Stock removed successfully.');
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  Future<void> _recordSale() async {
    final product = _product;
    if (product == null) return;

    final quantity = await _askQuantity(
      title: 'Record sale',
      action: 'Sell',
    );
    if (quantity == null || !mounted) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    try {
      final sale = await context.read<InventoryProvider>().recordSale(
            product.id,
            quantity,
          );
      if (mounted) {
        _showMessage(
          'Sale recorded: ${currencyFormatter.format(sale.totalAmount)}.',
        );
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  Future<int?> _askQuantity({
    required String title,
    required String action,
  }) async {
    final controller = TextEditingController();
    final quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity',
            prefixIcon: Icon(Icons.numbers),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value <= 0) return;
              Navigator.of(dialogContext).pop(value);
            },
            child: Text(action),
          ),
        ],
      ),
    );
    controller.dispose();
    return quantity;
  }

  void _showMessage(String message) {
    // The quantity dialog has just been popped. Wait until its OverlayEntry
    // has been deactivated before mutating the ScaffoldMessenger overlay.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final product = provider.find(widget.productId) ?? widget.product;

    if (product == null) {
      return const Scaffold(
        body: Center(child: Text('Product not found.')),
      );
    }

    final sales = provider.salesForProduct(product.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Product Management')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _ProductHeader(product: product),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _adjustStock(add: true),
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Add stock'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: product.stockQuantity == 0
                      ? null
                      : () => _adjustStock(add: false),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Remove stock'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: product.stockQuantity == 0 ? null : _recordSale,
              icon: const Icon(Icons.point_of_sale_outlined),
              label: const Text('Record sale'),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sales history',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 10),
          if (provider.salesLoading)
            const Center(child: CircularProgressIndicator())
          else if (provider.salesError != null)
            Text(
              provider.salesError!,
              style: const TextStyle(color: AppColors.danger),
            )
          else if (sales.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No sales recorded for this product yet.'),
              ),
            )
          else
            ...sales.map(
              (sale) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.successBg,
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.secondary,
                    ),
                  ),
                  title: Text(
                    '${sale.quantity} sold · ${currencyFormatter.format(sale.totalAmount)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${currencyFormatter.format(sale.sellingPrice)} each · ${dateFormatter.format(sale.soldAt)}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        product.photoUrl != null && File(product.photoUrl!).existsSync();
    return Card(
      color: product.isLowStock ? AppColors.warningBg : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: hasImage
                  ? Image.file(
                      File(product.photoUrl!),
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 84,
                      height: 84,
                      color: AppColors.accent.withValues(alpha: .25),
                      child: const Icon(Icons.inventory_2_outlined, size: 36),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(currencyFormatter.format(product.price)),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${product.stockQuantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: product.isLowStock
                          ? AppColors.warningText
                          : AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
