import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/product_controller.dart';
import '../Controllers/user_profile_controller.dart';
import '../Controllers/category_controller.dart';
import '../models/product_variant.dart';
import '../services/image_storage_service.dart';
import '../widgets/product_image.dart';

// All product-relevant images from assets/images
const List<Map<String, String>> _kAssetImages = [
  {'path': 'assets/images/shoe.jpg', 'label': 'Shoe'},
  {'path': 'assets/images/shoe2.jpg', 'label': 'Shoe 2'},
  {'path': 'assets/images/shoes2.jpg', 'label': 'Shoes'},
  {'path': 'assets/images/Lighthouse_MtBlk_R_700x.png', 'label': 'Boot'},
  {'path': 'assets/images/mens-sheep-skin-black-leather-bo.jpg', 'label': 'Leather Boot'},
  {'path': 'assets/images/Liberte-USA-Black-Varsity-Leathe.jpg', 'label': 'Leather Jacket'},
  {'path': 'assets/images/laptop.jpg', 'label': 'Laptop'},
  {'path': 'assets/images/polarized-sunglasses.jpg', 'label': 'Sunglasses'},
  {'path': 'assets/images/tomhawk_grey_wayfarer_polarized.jpg', 'label': 'Wayfarer'},
  {'path': 'assets/images/OIP.2HxDL5GRe5WJSuOHMI1qBwHaHa.png', 'label': 'Watch'},
  {'path': 'assets/images/OIP.nlU_OGN5YRPefZ87F74AUwHaHa.jpg', 'label': 'Watch 2'},
  {'path': 'assets/images/photo-1523275335684-37898b6baf30.jpg', 'label': 'Watch 3'},
  {'path': 'assets/images/photo-1572635196237-14b3f281503f.jpg', 'label': 'Glasses'},
  {'path': 'assets/images/pic22.jpg', 'label': 'Item'},
];

const List<String> _kSizeOptions = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const Color primaryColor = Color(0xFFFF5200);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _oldPriceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String? _selectedImage;
  String? _selectedCategory;
  final Set<String> _selectedSizes = {};
  final _imageUrlCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '10');

  final productController = ProductController.instance;
  final _profileController = UserProfileController.instance;
  final _categoryController = CategoryController.instance;
  final _imageService = UnconfiguredImageStorageService();

  bool get _isSeller => _profileController.isSeller;

  void _useImageUrl() {
    final url = _imageService.validateImageUrl(_imageUrlCtrl.text);
    if (url == null) {
      return;
    }
    setState(() => _selectedImage = url);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _oldPriceCtrl.dispose();
    _discountCtrl.dispose();
    _descriptionCtrl.dispose();
    _imageUrlCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  /// Generates a stable, unique-enough SKU for a given size from the
  /// product name and a fresh id — real uniqueness is guaranteed by the
  /// Firestore document id component, not the name-derived prefix.
  String _skuFor(String namePrefix, String size, String uniquePart) {
    final slug = namePrefix
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    return '$slug-$size-${uniquePart.substring(0, 6)}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      return;
    }
    if (_selectedCategory == null) {
      return;
    }
    if (_selectedSizes.isEmpty) {
      return;
    }

    final stockPerSize = int.tryParse(_stockCtrl.text.trim());
    if (stockPerSize == null || stockPerSize < 0) {
      return;
    }

    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final oldPrice = _oldPriceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_oldPriceCtrl.text.trim());
    final discount = _discountCtrl.text.trim().isEmpty ? null : _discountCtrl.text.trim();

    final uniquePart = DateTime.now().millisecondsSinceEpoch.toRadixString(36).padLeft(6, '0');
    final variants = _selectedSizes
        .map(
          (size) => ProductVariant(
            id: '$size-$uniquePart',
            sku: _skuFor(_nameCtrl.text, size, uniquePart),
            size: size,
            stock: stockPerSize,
          ),
        )
        .toList();

    // A seller's new listing needs admin approval before it's visible to
    // customers; an admin publishes their own immediately, matching the
    // behavior this screen always had.
    final sellerId = _isSeller ? (_profileController.currentUserId ?? '') : '';
    final status = _isSeller ? ProductStatus.pendingApproval : ProductStatus.published;

    final error = await productController.createProduct(
      imagePath: _selectedImage!,
      name: _nameCtrl.text.trim(),
      category: _selectedCategory!,
      currentPrice: price,
      oldPrice: oldPrice,
      discount: discount,
      availableSizes: _selectedSizes.toList(),
      description: _descriptionCtrl.text.trim(),
      sellerId: sellerId,
      status: status,
      variants: variants,
    );

    if (error == null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        title: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
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
              if (_selectedImage != null && _selectedImage!.startsWith('http')) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ProductImage(path: _selectedImage!, height: 140, width: double.infinity),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                '...or pick from the sample catalog:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              _ImagePicker(
                images: _kAssetImages,
                selected: _selectedImage,
                onSelect: (path) => setState(() => _selectedImage = path),
              ),
              const SizedBox(height: 20),

              // Name
              _sectionLabel('Product Name'),
              const SizedBox(height: 8),
              _input(
                _nameCtrl,
                'e.g. Air Max Sneaker',
                Icons.label,
                required: true,
                cardBg: cardBg,
              ),
              const SizedBox(height: 16),

              // Category
              _sectionLabel('Category'),
              const SizedBox(height: 8),
              Obx(() {
                final categories = _categoryController.categoryNames;
                if (categories.isEmpty) {
                  return Text(
                    'No categories yet — ask an admin to add some from the admin dashboard.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  );
                }
                return _CategoryPicker(
                  categories: categories,
                  selected: _selectedCategory,
                  onSelect: (c) => setState(() => _selectedCategory = c),
                );
              }),
              const SizedBox(height: 20),

              // Price row
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

              // Discount
              _sectionLabel('Discount Label (optional)'),
              const SizedBox(height: 8),
              _input(_discountCtrl, 'e.g. 20% OFF', Icons.percent, cardBg: cardBg),
              const SizedBox(height: 20),

              // Sizes
              _sectionLabel('Available Sizes'),
              const SizedBox(height: 8),
              _SizePicker(
                sizes: _kSizeOptions,
                selected: _selectedSizes,
                onToggle: (s) => setState(() {
                  _selectedSizes.contains(s) ? _selectedSizes.remove(s) : _selectedSizes.add(s);
                }),
              ),
              const SizedBox(height: 16),

              _sectionLabel('Stock per size'),
              const SizedBox(height: 4),
              Text(
                'Each selected size becomes its own tracked variant with this many units in stock.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              _input(
                _stockCtrl,
                '0',
                Icons.inventory_2_outlined,
                required: true,
                keyboardType: TextInputType.number,
                cardBg: cardBg,
              ),
              if (_isSeller) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade800, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'As a seller, this listing goes to an admin for review before it appears in the store.',
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Description
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

              // Submit button
              Obx(() {
                final loading = productController.isLoading.value;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Publish Product',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                );
              }),
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

// ─── Image Picker Grid ───────────────────────────────────────────────────────

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({required this.images, required this.selected, required this.onSelect});

  final List<Map<String, String>> images;
  final String? selected;
  final ValueChanged<String> onSelect;

  static const Color primaryColor = Color(0xFFFF5200);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, i) {
        final item = images[i];
        final path = item['path']!;
        final label = item['label']!;
        final isSelected = selected == path;

        return GestureDetector(
          onTap: () => onSelect(path),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey.shade300,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(path, fit: BoxFit.cover),
                  // Dark overlay + label at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Check icon when selected
                  if (isSelected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Category Chips ──────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.categories, required this.selected, required this.onSelect});

  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelect;

  static const Color primaryColor = Color(0xFFFF5200);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((c) {
        final isSelected = selected == c;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
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
  }
}

// ─── Size Chips ───────────────────────────────────────────────────────────────

class _SizePicker extends StatelessWidget {
  const _SizePicker({required this.sizes, required this.selected, required this.onToggle});

  final List<String> sizes;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  static const Color primaryColor = Color(0xFFFF5200);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: sizes.map((s) {
        final isSelected = selected.contains(s);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onToggle(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  s,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
