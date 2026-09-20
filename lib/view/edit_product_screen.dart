import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/category_controller.dart';
import '../Controllers/product_controller.dart';
import '../Controllers/user_profile_controller.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../services/image_storage_service.dart';
import '../widgets/product_image.dart';

const List<String> _kSizeOptions = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

/// Lets a seller (their own listing) or an admin (any listing) edit stock,
/// variants, SKU, price, and other catalog fields after creation — the gap
/// AddProductScreen intentionally didn't cover (it only ever creates). Also
/// where a listing gets archived/reactivated: firestore.rules lets a seller
/// move their own product to any status except `published`/`rejected`
/// (those stay an admin approval action), which is exactly the asymmetry
/// [_toggleArchived] below mirrors.
class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key, required this.product});

  final Product product;

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  static const Color primaryColor = Color(0xFFFF5200);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _oldPriceCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _totalStockCtrl;

  final _imageService = UnconfiguredImageStorageService();
  final _profileController = UserProfileController.instance;
  final _categoryController = CategoryController.instance;
  final _productController = ProductController.instance;

  late String _imagePath;
  late String? _category;
  // size -> stock/sku/variantId, seeded from the product's existing
  // variants. Editing stock/adding/removing a size all just mutate this map;
  // the actual ProductVariant list is only rebuilt from it on submit.
  late Map<String, int> _variantStock;
  late Map<String, String> _variantSku;
  late Map<String, String> _variantId;
  late bool _tracksVariants;

  bool _saving = false;

  bool get _isAdmin => _profileController.isAdmin;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p.name);
    _priceCtrl = TextEditingController(text: p.currentPrice.toStringAsFixed(2));
    _oldPriceCtrl = TextEditingController(text: p.oldPrice?.toStringAsFixed(2) ?? '');
    _discountCtrl = TextEditingController(text: p.discount ?? '');
    _descriptionCtrl = TextEditingController(text: p.description);
    _imageUrlCtrl = TextEditingController(text: p.imagePath.startsWith('http') ? p.imagePath : '');
    _skuCtrl = TextEditingController(text: p.sku ?? '');
    _totalStockCtrl = TextEditingController(text: p.totalStock?.toString() ?? '');
    _imagePath = p.imagePath;
    _category = p.category;
    _tracksVariants = p.hasVariants;
    _variantStock = {for (final v in p.variants) v.size: v.stock};
    _variantSku = {for (final v in p.variants) v.size: v.sku};
    _variantId = {for (final v in p.variants) v.size: v.id};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _oldPriceCtrl.dispose();
    _discountCtrl.dispose();
    _descriptionCtrl.dispose();
    _imageUrlCtrl.dispose();
    _skuCtrl.dispose();
    _totalStockCtrl.dispose();
    super.dispose();
  }

  void _useImageUrl() {
    final url = _imageService.validateImageUrl(_imageUrlCtrl.text);
    if (url == null) {
      return;
    }
    setState(() => _imagePath = url);
  }

  String _skuFor(String size) {
    final slug = _nameCtrl.text
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    final unique = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return '$slug-$size-${unique.substring(unique.length - 6)}';
  }

  void _toggleSize(String size) {
    setState(() {
      if (_variantStock.containsKey(size)) {
        _variantStock.remove(size);
        _variantSku.remove(size);
        _variantId.remove(size);
      } else {
        _variantStock[size] = 0;
        _variantSku[size] = _skuFor(size);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    List<ProductVariant> variants = const [];
    int? totalStock;

    if (_tracksVariants) {
      if (_variantStock.isEmpty) {
        return;
      }
      variants = _variantStock.entries
          .map(
            (e) => ProductVariant(
              id: _variantId[e.key] ?? '${e.key}-${DateTime.now().millisecondsSinceEpoch}',
              sku: _variantSku[e.key] ?? _skuFor(e.key),
              size: e.key,
              stock: e.value,
            ),
          )
          .toList();
    } else {
      final raw = _totalStockCtrl.text.trim();
      totalStock = raw.isEmpty ? null : int.tryParse(raw);
      if (raw.isNotEmpty && totalStock == null) {
        return;
      }
    }

    setState(() => _saving = true);

    final price = double.tryParse(_priceCtrl.text.trim()) ?? widget.product.currentPrice;
    final oldPrice = _oldPriceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_oldPriceCtrl.text.trim());
    final discount = _discountCtrl.text.trim().isEmpty ? null : _discountCtrl.text.trim();
    final sku = _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim();

    final error = await _productController.updateProduct(
      productId: widget.product.id,
      imagePath: _imagePath,
      name: _nameCtrl.text.trim(),
      category: _category,
      currentPrice: price,
      oldPrice: oldPrice,
      discount: discount,
      availableSizes: _tracksVariants ? variants.map((v) => v.size).toList() : null,
      description: _descriptionCtrl.text.trim(),
      sku: sku,
      variants: variants,
      totalStock: totalStock,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error == null) {
      Get.back();
    }
  }

  Future<void> _toggleArchived() async {
    final isArchived = widget.product.status == ProductStatus.archived;
    final newStatus = isArchived
        ? (_isAdmin ? ProductStatus.published : ProductStatus.pendingApproval)
        : ProductStatus.archived;

    final error = await _productController.updateProductStatus(widget.product.id, newStatus);
    if (!mounted) return;

    if (error == null) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final isArchived = widget.product.status == ProductStatus.archived;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: isArchived ? 'Reactivate' : 'Archive',
            icon: Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
            onPressed: _toggleArchived,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isArchived)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.archive_outlined, color: Colors.blueGrey, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This listing is archived and hidden from the storefront.',
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ),
                    ],
                  ),
                ),

              _sectionLabel('Product Image'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        hintText: 'https://example.com/photo.jpg',
                        prefixIcon: Icon(Icons.link, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _useImageUrl, child: const Text('Use URL')),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ProductImage(path: _imagePath, height: 140, width: double.infinity),
              ),
              const SizedBox(height: 20),

              _sectionLabel('Product Name'),
              const SizedBox(height: 8),
              _input(_nameCtrl, 'e.g. Air Max Sneaker', Icons.label, required: true, cardBg: cardBg),
              const SizedBox(height: 16),

              _sectionLabel('Category'),
              const SizedBox(height: 8),
              Obx(() {
                final options = {
                  ..._categoryController.categoryNames,
                  if (_category != null) _category!,
                };
                if (options.isEmpty) {
                  return Text(
                    'No categories yet — ask an admin to add some from the admin dashboard.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((c) {
                    final isSelected = _category == c;
                    return GestureDetector(
                      onTap: () => setState(() => _category = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.transparent,
                          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Price (\$)'),
                        const SizedBox(height: 8),
                        _input(
                          _priceCtrl,
                          '0.00',
                          Icons.attach_money,
                          required: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          cardBg: cardBg,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Old Price (optional)'),
                        const SizedBox(height: 8),
                        _input(
                          _oldPriceCtrl,
                          '0.00',
                          Icons.money_off,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          cardBg: cardBg,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _sectionLabel('Discount Label (optional)'),
              const SizedBox(height: 8),
              _input(_discountCtrl, 'e.g. 20% OFF', Icons.percent, cardBg: cardBg),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionLabel('Track stock by size (variants)'),
                  Switch(
                    value: _tracksVariants,
                    onChanged: (v) => setState(() => _tracksVariants = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_tracksVariants) ...[
                Text(
                  'Each selected size is its own tracked variant with its own stock and SKU.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kSizeOptions.map((s) {
                    final isSelected = _variantStock.containsKey(s);
                    return GestureDetector(
                      onTap: () => _toggleSize(s),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.transparent,
                          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                for (final size in _variantStock.keys.toList())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(size, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('stock-$size'),
                            initialValue: '${_variantStock[size]}',
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Stock',
                              filled: true,
                              fillColor: cardBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (v) =>
                                _variantStock[size] = int.tryParse(v.trim()) ?? _variantStock[size]!,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            key: ValueKey('sku-$size'),
                            initialValue: _variantSku[size],
                            decoration: InputDecoration(
                              labelText: 'SKU',
                              filled: true,
                              fillColor: cardBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (v) => _variantSku[size] = v.trim(),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove size',
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => setState(() => _toggleSize(size)),
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                _sectionLabel('Total Stock (optional)'),
                const SizedBox(height: 4),
                Text(
                  'Leave blank to keep stock untracked (always orderable).',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                _input(
                  _totalStockCtrl,
                  'e.g. 25',
                  Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                  cardBg: cardBg,
                ),
                const SizedBox(height: 16),
                _sectionLabel('SKU (optional)'),
                const SizedBox(height: 8),
                _input(_skuCtrl, 'e.g. SHOE-001', Icons.qr_code, cardBg: cardBg),
              ],
              const SizedBox(height: 20),

              _sectionLabel('Description'),
              const SizedBox(height: 8),
              _input(
                _descriptionCtrl,
                'Describe your product...',
                Icons.description,
                maxLines: 3,
                cardBg: cardBg,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) =>
      Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));

  Widget _input(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    required Color cardBg,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return 'Required';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
    );
  }
}
