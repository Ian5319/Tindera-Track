import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/product.dart';

Future<Product?> showProductEditDialog(
  BuildContext context,
  Product product,
) {
  return showDialog<Product>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ProductEditDialog(product: product),
  );
}

class _ProductEditDialog extends StatefulWidget {
  const _ProductEditDialog({required this.product});

  final Product product;

  @override
  State<_ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<_ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _threshold;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product.name);
    _price =
        TextEditingController(text: widget.product.price.toStringAsFixed(2));
    _threshold =
        TextEditingController(text: widget.product.threshold.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _threshold.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final price = Validators.parseMoney(_price.text);
    final threshold = int.tryParse(_threshold.text.trim());
    if (price == null || threshold == null) return;

    Navigator.of(context).pop(
      widget.product.copyWith(
        name: _name.text.trim(),
        price: price,
        threshold: threshold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit product'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: 200,
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    Validators.requiredField(value, 'Product name'),
                decoration: const InputDecoration(
                  labelText: 'Product name',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                validator: Validators.money,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Selling price',
                  prefixText: '₱ ',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _threshold,
                validator: (value) =>
                    Validators.integer(value, 'Low-stock threshold'),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Low-stock threshold',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save changes'),
        ),
      ],
    );
  }
}
