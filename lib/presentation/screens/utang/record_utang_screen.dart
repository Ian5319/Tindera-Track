import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/utang_transaction.dart';
import '../../providers/utang_provider.dart';
import '../../widgets/common/custom_button.dart';

class RecordUtangScreen extends StatefulWidget {
  const RecordUtangScreen({super.key});

  @override
  State<RecordUtangScreen> createState() => _RecordUtangScreenState();
}

class _RecordUtangScreenState extends State<RecordUtangScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerName = TextEditingController();
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  final _picker = ImagePicker();

  XFile? _photo;
  bool _saving = false;

  @override
  void dispose() {
    _customerName.dispose();
    _phone.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _attachPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (picked != null && mounted) {
      setState(() {
        _photo = picked;
      });
    }
  }

  double get amount {
    return double.tryParse(
          _amount.text.replaceAll(',', ''),
        ) ??
        0;
  }

  double get afterEntry {
    return amount;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Attach a photo as transaction proof.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final provider = context.read<UtangProvider>();

      // Create the customer manually from the entered information.
      final customer = await provider.createCustomer(
        name: _customerName.text.trim(),
        phone: _phone.text.trim(),
      );

      final tx = UtangTransaction(
        id: 't${DateTime.now().microsecondsSinceEpoch}',
        customerId: customer.id,
        amount: amount,
        type: UtangType.credit,
        photoUrl: _photo!.path,
        note: _note.text.trim().isEmpty
            ? null
            : _note.text.trim(),
        createdAt: DateTime.now(),
      );

      await provider.addTransaction(tx);

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Utang sale recorded and customer saved.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save utang sale. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Utang Sale'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _customerName,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the customer name.';
                }

                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Customer name',
                hintText: 'Who owes this utang?',
                prefixIcon: Icon(
                  Icons.person_outline,
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number (optional)',
                hintText: '09171234567',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Card(
              color: AppColors.warningBg,
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current balance',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '₱0.00',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.warningText,
                      size: 34,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _amount,
              validator: Validators.money,
              onChanged: (_) {
                setState(() {});
              },
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₱ ',
                prefixIcon: Icon(
                  Icons.payments_outlined,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              color: AppColors.successBg,
              child: ListTile(
                title: const Text(
                  'Balance after entry',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  currencyFormatter.format(afterEntry),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                  ),
                ),
                trailing: const Icon(
                  Icons.trending_up,
                  color: AppColors.secondary,
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'What was purchased?',
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: InkWell(
                onTap: _attachPhoto,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.accent
                              .withValues(alpha: .22),
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attach Photo',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Photo proof is required for credit sales.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_photo != null) ...[
              const SizedBox(height: 10),

              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(_photo!.path),
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 22),

            CustomButton(
              label: 'Save Utang Sale',
              icon: Icons.save_outlined,
              onPressed: _save,
              loading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}