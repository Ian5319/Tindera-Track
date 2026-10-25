import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/utang_transaction.dart';
import '../../../services/media_storage_service.dart';
import '../../providers/payment_provider.dart';
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
  final _mediaStorage = MediaStorageService();

  Customer? _selectedCustomer;
  XFile? _attachment;
  Uint8List? _attachmentBytes;
  bool _saving = false;

  @override
  void dispose() {
    _customerName.dispose();
    _phone.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _selectExistingCustomer(Customer selected) {
    setState(() {
      _selectedCustomer = selected;
      _customerName.text = selected.name;
      _phone.text = selected.phone;
    });
  }

  double get amount {
    final parsed = Validators.parseMoney(_amount.text);
    return parsed ?? 0;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw StateError('Utang photos must be smaller than 5 MB.');
      }
      if (!mounted) return;
      setState(() {
        _attachment = file;
        _attachmentBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message
                : 'Could not attach the photo. Check camera or photo permissions.',
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    String? uploadedPhotoUrl;
    try {
      final provider = context.read<UtangProvider>();

      final customer = _selectedCustomer ??
          await provider.createCustomer(
            name: _customerName.text.trim(),
            phone: _phone.text.trim(),
          );

      final transactionId = 't${DateTime.now().microsecondsSinceEpoch}';
      if (_attachment != null) {
        uploadedPhotoUrl = await _mediaStorage.uploadUtangPhoto(
          transactionId: transactionId,
          file: _attachment!,
        );
      }

      final tx = UtangTransaction(
        id: transactionId,
        customerId: customer.id,
        amount: amount,
        type: UtangType.credit,
        photoUrl: uploadedPhotoUrl,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
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
            'Utang sale recorded.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (uploadedPhotoUrl != null) {
        try {
          await _mediaStorage.deleteOwnedPhoto(uploadedPhotoUrl);
        } catch (_) {
          // The record failure is the primary error; cleanup is best effort.
        }
      }
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError || error is ArgumentError
                ? error.toString().replaceFirst(RegExp(r'^\w+Error: '), '')
                : 'Unable to save utang sale. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final selectedCustomer = _selectedCustomer;
    final currentBalance = selectedCustomer == null
        ? 0.0
        : paymentProvider.remainingForCustomer(
            customerId: selectedCustomer.id,
            utangBalance: selectedCustomer.balance,
          );
    final afterEntry = currentBalance + amount;

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
              maxLength: 200,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_selectedCustomer != null) {
                  setState(() => _selectedCustomer = null);
                }
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the customer name.';
                }

                return null;
              },
              decoration: InputDecoration(
                labelText: 'Customer name',
                hintText: 'Enter a new name or choose from the list',
                suffixIcon: PopupMenuButton<Customer>(
                  tooltip: 'Choose an existing customer',
                  icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                  onSelected: _selectExistingCustomer,
                  itemBuilder: (_) {
                    final customers =
                        context.read<UtangProvider>().customers.toList();

                    if (customers.isEmpty) {
                      return const [
                        PopupMenuItem<Customer>(
                          enabled: false,
                          child: Text('No existing customers yet'),
                        ),
                      ];
                    }

                    return customers
                        .map(
                          (customer) => PopupMenuItem<Customer>(
                            value: customer,
                            child: Text(
                              '${customer.name} • ${currencyFormatter.format(paymentProvider.remainingForCustomer(customerId: customer.id, utangBalance: customer.balance))}',
                            ),
                          ),
                        )
                        .toList();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              maxLength: 32,
              keyboardType: TextInputType.phone,
              onChanged: (_) {
                if (_selectedCustomer != null) {
                  setState(() => _selectedCustomer = null);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Phone number (optional)',
                hintText: '09171234567',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.warningBg,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current balance',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            currencyFormatter.format(currentBalance),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
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
              keyboardType: const TextInputType.numberWithOptions(
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
              maxLength: 2000,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'What was purchased?',
              ),
            ),
            const SizedBox(height: 16),
            _PhotoAttachmentCard(
              bytes: _attachmentBytes,
              onCamera: () => _pickPhoto(ImageSource.camera),
              onGallery: () => _pickPhoto(ImageSource.gallery),
              onRemove: _attachment == null
                  ? null
                  : () => setState(() {
                        _attachment = null;
                        _attachmentBytes = null;
                      }),
            ),
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

class _PhotoAttachmentCard extends StatelessWidget {
  const _PhotoAttachmentCard({
    required this.bytes,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Photo evidence (optional)',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text('Attach the purchased items or written ledger entry.'),
            if (bytes != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  bytes!,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(bytes == null ? 'Take photo' : 'Retake'),
                ),
                OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose photo'),
                ),
                if (onRemove != null)
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
