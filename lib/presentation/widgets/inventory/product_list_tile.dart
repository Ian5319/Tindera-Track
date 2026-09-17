import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';

class ProductListTile extends StatelessWidget {
  const ProductListTile({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final low = product.isLowStock;
    return Card(
      color: low ? AppColors.warningBg : Colors.white,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: _thumb(),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text('${currencyFormatter.format(product.price)}  •  ${product.stockQuantity} in stock')),
        trailing: low
            ? const Icon(Icons.warning_amber_rounded, color: AppColors.warningText)
            : const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _thumb() {
    if (product.photoUrl != null && File(product.photoUrl!).existsSync()) {
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(product.photoUrl!), width: 52, height: 52, fit: BoxFit.cover));
    }
    return Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.accent.withValues( alpha: .25), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.inventory_2_outlined));
  }
}
