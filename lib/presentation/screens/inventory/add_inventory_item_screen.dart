import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/product.dart';
import '../../../services/camera_service.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/common/custom_button.dart';

class AddInventoryItemScreen extends StatefulWidget {
  const AddInventoryItemScreen({super.key, this.product});
  final Product? product;
  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _threshold = TextEditingController(text: '5');
  final _camera = CameraService();
  final _picker = ImagePicker();
  XFile? _captured;
  bool _cameraLoading = true;
  String? _cameraError;
  bool _saving = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text = p.name; _price.text = p.price.toStringAsFixed(2); _stock.text = p.stockQuantity.toString(); _threshold.text = p.threshold.toString();
      if (p.photoUrl != null) _captured = XFile(p.photoUrl!);
      _cameraLoading = false;
    } else {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try { await _camera.initialize(); } catch (e) { _cameraError = 'Camera could not start on this device.'; } finally { if (mounted) setState(() => _cameraLoading = false); }
  }

  Future<void> _takePhoto() async {
    try { final file = await _camera.takePhoto(); if (mounted) setState(() => _captured = file); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not capture the photo. Please try again.'))); }
  }

  Future<void> _useGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) setState(() => _captured = file);
  }

  Future<void> _save() async {
    if (_captured == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Take a product photo first.'))); return; }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final product = Product(
      id: widget.product?.id ?? 'p${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      price: double.parse(_price.text.replaceAll(',', '')),
      stockQuantity: int.parse(_stock.text),
      threshold: int.parse(_threshold.text),
      photoUrl: _captured?.path,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
    );
    await context.read<InventoryProvider>().saveProduct(product);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Inventory item updated.' : 'Item added to inventory.')));
    context.pop();
  }

  @override
  void dispose() {
    _camera.dispose();
    _name.dispose(); _price.dispose(); _stock.dispose(); _threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Inventory Item' : 'Add Inventory Item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _cameraPane(),
            if (_captured != null) ...[
              const SizedBox(height: 20),
              const Text('Product details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                validator: (v) => Validators.requiredField(v, 'Product name'),
                decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.label_outline)),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextFormField(controller: _price, validator: Validators.money, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price', prefixText: '₱ '))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _stock, validator: (v) => Validators.integer(v), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Quantity'))),
              ]),
              const SizedBox(height: 14),
              TextFormField(controller: _threshold, validator: (v) => Validators.integer(v, 'Low-stock threshold'), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low-stock threshold', helperText: 'Alert when stock is at or below this number.')),
              const SizedBox(height: 22),
              CustomButton(label: isEditing ? 'Save Changes' : 'Save Item', icon: Icons.save_outlined, onPressed: _save, loading: _saving),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cameraPane() {
    final controller = _camera.controller;
    Widget preview;
    if (_captured != null && File(_captured!.path).existsSync()) {
      preview = Stack(fit: StackFit.expand, children: [
        Image.file(File(_captured!.path), fit: BoxFit.cover),
        Positioned(left: 14, bottom: 14, child: FilledButton.tonalIcon(onPressed: _initCamera, icon: const Icon(Icons.refresh), label: const Text('Retake'))),
      ]);
    } else if (_cameraLoading) {
      preview = const Center(child: CircularProgressIndicator(color: Colors.white));
    } else if (_cameraError != null) {
      preview = Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.no_photography_outlined, color: Colors.white, size: 50),
        const SizedBox(height: 12),
        Text(_cameraError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _useGallery, icon: const Icon(Icons.photo_library_outlined), label: const Text('Choose Photo')),
      ])));
    } else if (controller != null && controller.value.isInitialized) {
      preview = Stack(fit: StackFit.expand, children: [
        CameraPreview(controller),
        Center(child: Container(width: 230, height: 230, decoration: BoxDecoration(border: Border.all(color: AppColors.accent, width: 3), borderRadius: BorderRadius.circular(20)))),
        const Positioned(top: 18, left: 0, right: 0, child: Center(child: Text('Align Product in Frame', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, shadows: [Shadow(blurRadius: 4, color: Colors.black)])))),
      ]);
    } else {
      preview = const Center(child: Text('Camera unavailable', style: TextStyle(color: Colors.white)));
    }

    return Column(children: [
      Container(height: 330, width: double.infinity, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)), clipBehavior: Clip.antiAlias, child: preview),
      const SizedBox(height: 12),
      CustomButton(label: 'Take Photo', icon: Icons.camera_alt, onPressed: controller != null && controller.value.isInitialized ? _takePhoto : _useGallery),
      if (_captured == null) ...[const SizedBox(height: 8), Center(child: TextButton.icon(onPressed: _useGallery, icon: const Icon(Icons.photo_library_outlined), label: const Text('Use a photo from gallery')))],
    ]);
  }
}
