import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/product_controller.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const Color primaryColor = Color(0xFFFF5200);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _imagePathCtrl = TextEditingController(text: 'assets/images/shoe.jpg');
  final _priceCtrl = TextEditingController();
  final _oldPriceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _sizesCtrl = TextEditingController(text: 'S,M,L');
  final _descriptionCtrl = TextEditingController();

  final productController = ProductController.instance;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _imagePathCtrl.dispose();
    _priceCtrl.dispose();
    _oldPriceCtrl.dispose();
    _discountCtrl.dispose();
    _sizesCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final sizes = _sizesCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final oldPrice = _oldPriceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_oldPriceCtrl.text.trim());
    final discount = _discountCtrl.text.trim().isEmpty
        ? null
        : _discountCtrl.text.trim();

    final error = await productController.createProduct(
      imagePath: _imagePathCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      currentPrice: price,
      oldPrice: oldPrice,
      discount: discount,
      availableSizes: sizes,
      description: _descriptionCtrl.text.trim(),
    );

    if (error == null) {
      Get.snackbar(
        'Success',
        'Product added',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Navigator.pop(context);
    } else {
      Get.snackbar(
        'Error',
        error,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _input(_nameCtrl, 'Name', Icons.label, required: true),
              _input(_categoryCtrl, 'Category', Icons.category, required: true),
              _input(_imagePathCtrl, 'Image Path or URL', Icons.image),
              _input(
                _priceCtrl,
                'Current Price',
                Icons.attach_money,
                required: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              _input(
                _oldPriceCtrl,
                'Old Price (optional)',
                Icons.money_off,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              _input(
                _discountCtrl,
                'Discount (e.g. 20% OFF)',
                Icons.percent,
              ),
              _input(
                _sizesCtrl,
                'Available Sizes (comma separated)',
                Icons.format_list_bulleted,
              ),
              _input(
                _descriptionCtrl,
                'Description',
                Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Obx(() {
                final loading = productController.isLoading.value;
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Add Product',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return 'Required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor),
          ),
        ),
      ),
    );
  }
}



