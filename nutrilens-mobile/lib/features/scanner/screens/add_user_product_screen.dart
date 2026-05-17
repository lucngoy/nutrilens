import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_product_model.dart';
import '../services/user_product_service.dart';

class AddUserProductScreen extends StatefulWidget {
  final String barcode;
  final UserProductModel? product; // non-null = edit mode

  const AddUserProductScreen({
    super.key,
    this.barcode = '',
    this.product,
  });

  @override
  State<AddUserProductScreen> createState() => _AddUserProductScreenState();
}

class _AddUserProductScreenState extends State<AddUserProductScreen> {
  static const primaryColor = Color(0xFFEC6F2D);

  bool get _isEdit => widget.product != null;

  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;
  File? _imageFile;

  late final _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
  late final _brandCtrl = TextEditingController(text: widget.product?.brand ?? '');
  late final _servingSizeCtrl = TextEditingController(
      text: widget.product?.servingSize.toString() ?? '100');
  late String _servingUnit = widget.product?.servingUnit ?? 'g';
  late final _caloriesCtrl = TextEditingController(
      text: widget.product?.calories?.toString() ?? '');
  late final _proteinCtrl = TextEditingController(
      text: widget.product?.protein?.toString() ?? '');
  late final _carbsCtrl = TextEditingController(
      text: widget.product?.carbohydrates?.toString() ?? '');
  late final _fatCtrl = TextEditingController(
      text: widget.product?.fat?.toString() ?? '');
  late final _sugarCtrl = TextEditingController(
      text: widget.product?.sugar?.toString() ?? '');
  late final _saltCtrl = TextEditingController(
      text: widget.product?.salt?.toString() ?? '');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _servingSizeCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _sugarCtrl.dispose();
    _saltCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take a photo'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
          if (_imageFile != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(context); setState(() => _imageFile = null); },
            ),
        ]),
      ),
    );
  }

  Widget _emptyPhoto() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.add_a_photo_outlined, size: 36, color: primaryColor.withOpacity(0.6)),
    const SizedBox(height: 8),
    const Text('Add product photo',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black38)),
    const SizedBox(height: 4),
    const Text('Optional — helps identify the product',
        style: TextStyle(fontSize: 11, color: Colors.black26)),
  ]);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    try {
      // Evict old image from Flutter's network cache so all widgets show the new one
      if (_isEdit && _imageFile != null && widget.product?.imageUrl != null) {
        NetworkImage(widget.product!.imageUrl!).evict();
      }

      final data = UserProductModel(
        id: widget.product?.id,
        barcode: widget.product?.barcode ?? widget.barcode,
        name: _nameCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        servingSize: double.tryParse(_servingSizeCtrl.text) ?? 100,
        servingUnit: _servingUnit,
        calories: double.tryParse(_caloriesCtrl.text),
        protein: double.tryParse(_proteinCtrl.text),
        carbohydrates: double.tryParse(_carbsCtrl.text),
        fat: double.tryParse(_fatCtrl.text),
        sugar: double.tryParse(_sugarCtrl.text),
        salt: double.tryParse(_saltCtrl.text),
      );
      final svc = UserProductService();
      final saved = _isEdit
          ? await svc.update(widget.product!.id!, data, imagePath: _imageFile?.path)
          : await svc.create(data, imagePath: _imageFile?.path);
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      setState(() { _error = 'Failed to save product. Please try again.'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(_isEdit ? 'Edit product' : 'Add product',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Photo picker
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (_imageFile != null || (widget.product?.imageUrl != null))
                          ? primaryColor
                          : const Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageFile != null
                      ? Stack(fit: StackFit.expand, children: [
                          Image.file(_imageFile!, fit: BoxFit.cover),
                          Positioned(
                            bottom: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 16),
                            ),
                          ),
                        ])
                      : (widget.product?.imageUrl != null && widget.product!.imageUrl!.isNotEmpty)
                          ? Stack(fit: StackFit.expand, children: [
                              Image.network(widget.product!.imageUrl!, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _emptyPhoto()),
                              Positioned(
                                bottom: 8, right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                ),
                              ),
                            ])
                          : _emptyPhoto(),
                ),
              ),
              const SizedBox(height: 16),

              // Barcode chip (create mode only)
              if (!_isEdit && widget.barcode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.qr_code, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text('Barcode: ${widget.barcode}',
                        style: const TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w500)),
                  ]),
                ),

              _Section(title: 'Product info', children: [
                _Field(label: 'Name *', controller: _nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _Field(label: 'Brand (optional)', controller: _brandCtrl),
              ]),
              const SizedBox(height: 16),

              _Section(title: 'Serving size', children: [
                Row(children: [
                  Expanded(
                    child: _Field(
                      label: 'Amount',
                      controller: _servingSizeCtrl,
                      numeric: true,
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _servingUnit,
                              isExpanded: true,
                              items: ['g', 'ml', 'oz', 'cup', 'tbsp', 'tsp', 'piece']
                                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) => setState(() => _servingUnit = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ]),
              const SizedBox(height: 16),

              _Section(title: 'Nutrition (per serving)', children: [
                _NutritionRow(label: 'Calories (kcal)', controller: _caloriesCtrl),
                const SizedBox(height: 10),
                _NutritionRow(label: 'Protein (g)', controller: _proteinCtrl),
                const SizedBox(height: 10),
                _NutritionRow(label: 'Carbohydrates (g)', controller: _carbsCtrl),
                const SizedBox(height: 10),
                _NutritionRow(label: 'Fat (g)', controller: _fatCtrl),
                const SizedBox(height: 10),
                _NutritionRow(label: 'Sugar (g)', controller: _sugarCtrl),
                const SizedBox(height: 10),
                _NutritionRow(label: 'Salt (g)', controller: _saltCtrl),
              ]),
              const SizedBox(height: 16),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(_isEdit ? 'Save changes' : 'Save product',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54)),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool numeric;
  final String? Function(String?)? validator;
  const _Field({required this.label, required this.controller, this.numeric = false, this.validator});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: numeric ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))] : [],
        validator: validator,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ],
  );
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _NutritionRow({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54))),
      SizedBox(
        width: 100,
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '—',
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ),
    ],
  );
}
