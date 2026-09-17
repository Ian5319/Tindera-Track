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
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _picker = ImagePicker();
  String? _customerId;
  XFile? _photo;
  bool _saving = false;

  @override
  void dispose() { _amount.dispose(); _note.dispose(); super.dispose(); }

  Future<void> _attachPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null && mounted) setState(() => _photo = picked);
  }

  double get currentBalance {
    if (_customerId == null) return 0;
    return context.read<UtangProvider>().balance(_customerId!);
  }

  double get afterEntry {
    final amount = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    return currentBalance + amount;
  }

  Future<void> _save() async {
    if (_customerId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a customer first.'))); return; }
    if (_photo == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attach a photo as transaction proof.'))); return; }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final tx = UtangTransaction(id: 't${DateTime.now().microsecondsSinceEpoch}', customerId: _customerId!, amount: double.parse(_amount.text.replaceAll(',', '')), type: UtangType.credit, photoUrl: _photo!.path, note: _note.text.trim().isEmpty ? null : _note.text.trim(), createdAt: DateTime.now());
    await context.read<UtangProvider>().addTransaction(tx);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utang sale recorded and balance updated.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UtangProvider>();
    final selected = _customerId == null ? null : provider.customer(_customerId!);
    return Scaffold(appBar: AppBar(title: const Text('Record Utang Sale')), body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      DropdownButtonFormField<String>(initialValue: _customerId, validator: (v) => v == null ? 'Select a customer.' : null, decoration: const InputDecoration(labelText: 'Customer', prefixIcon: Icon(Icons.person_outline)), items: provider.customers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} • ${c.phone}'))).toList(), onChanged: (v) => setState(() => _customerId = v)),
      const SizedBox(height: 16),
      Card(color: AppColors.warningBg, child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Current balance', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text(currencyFormatter.format(selected?.balance ?? 0), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24))])), const Icon(Icons.account_balance_wallet_outlined, color: AppColors.warningText, size: 34)]))),
      const SizedBox(height: 16),
      TextFormField(controller: _amount, validator: Validators.money, onChanged: (_) => setState(() {}), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', prefixText: '₱ ', prefixIcon: Icon(Icons.payments_outlined))),
      const SizedBox(height: 12),
      Card(color: AppColors.successBg, child: ListTile(title: const Text('Balance after entry', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(currencyFormatter.format(afterEntry), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.secondary)), trailing: const Icon(Icons.trending_up, color: AppColors.secondary))),
      const SizedBox(height: 16),
      TextFormField(controller: _note, maxLines: 2, decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'What was purchased?')),
      const SizedBox(height: 16),
      Card(
        child: InkWell(
          onTap: _attachPhoto,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(width: 54, height: 54, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: .22), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary)),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Attach Photo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), SizedBox(height: 4), Text('Photo proof is required for credit sales.')])),
            ]),
          ),
        ),
      ),
      if (_photo != null) ...[const SizedBox(height: 10), ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(File(_photo!.path), height: 180, fit: BoxFit.cover))],
      const SizedBox(height: 22),
      CustomButton(label: 'Save Utang Sale', icon: Icons.save_outlined, onPressed: _save, loading: _saving),
    ])));
  }
}
