import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(color: product.isLowStock ? AppColors.warningBg : Colors.white, child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700))), if (product.isLowStock) const Icon(Icons.warning_amber_rounded, color: AppColors.warningText)]),
    const Spacer(), Text(currencyFormatter.format(product.price), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 4), Text('${product.stockQuantity} left'),
  ]))));
}
