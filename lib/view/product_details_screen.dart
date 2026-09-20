import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../Controllers/cart_controller.dart';
import '../Controllers/review_controller.dart';
import '../Controllers/wishlist_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/rating_stars.dart';
import '../widgets/product_image.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? _selectedSize;

  bool get _hasVariants => widget.product.hasVariants;

  List<String> get _sizeOptions => _hasVariants
      ? widget.product.variants.map((v) => v.size).toList()
      : widget.product.availableSizes;

  ProductVariant? get _selectedVariant {
    if (!_hasVariants || _selectedSize == null) return null;
    for (final v in widget.product.variants) {
      if (v.size == _selectedSize) return v;
    }
    return null;
  }

  /// Stock for the current selection: the variant's stock when the product
  /// has variants, the product's untracked/total stock otherwise. Null
  /// means "not tracked" — always orderable, matching every pre-upgrade
  /// product that has no stock field at all.
  int? get _availableStock => _hasVariants ? _selectedVariant?.stock : widget.product.totalStock;

  bool get _selectionInStock => _availableStock == null || _availableStock! > 0;

  double get _effectivePrice =>
      _selectedVariant?.effectivePrice(widget.product.currentPrice) ?? widget.product.currentPrice;

  @override
  void initState() {
    super.initState();
    ReviewController.instance.fetchReviewsForProduct(widget.product.id);
    if (_sizeOptions.isNotEmpty) {
      // Prefer the first size that's actually in stock, so a product with a
      // mix of in-stock and sold-out sizes doesn't default to a dead end.
      _selectedSize = _sizeOptions.firstWhere((size) {
        if (!_hasVariants) return true;
        final variant = widget.product.variants.firstWhere((v) => v.size == size);
        return variant.stock > 0;
      }, orElse: () => _sizeOptions.first);
    }
  }

  String _formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

  Future<void> _addToCart() async {
    if (_selectedSize == null) {
      return;
    }
    if (!_selectionInStock) {
      return;
    }

    await CartController.instance.addToCart(
      product: widget.product,
      selectedSize: _selectedSize!,
      quantity: 1,
    );
  }

  void _buyNow() {
    if (_selectedSize == null) {
      return;
    }
    if (!_selectionInStock) {
      return;
    }
    Get.toNamed(AppRoutes.checkout, arguments: {'totalAmount': _effectivePrice, 'itemCount': 1});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Get.back()),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text:
                    'Check out ${widget.product.name} on Zentra — ${_formatPrice(widget.product.currentPrice)}',
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Hero(
                    tag: 'product-image-${widget.product.id}',
                    child: ProductImage(path: widget.product.imagePath, width: double.infinity),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                      child: Obx(() {
                        final wishlistController = WishlistController.instance;
                        final isInWishlist = wishlistController.isInWishlist(widget.product.id);
                        return IconButton(
                          icon: Icon(
                            isInWishlist ? Icons.favorite : Icons.favorite_border,
                            color: isInWishlist ? Colors.red : Colors.black,
                            size: 28,
                          ),
                          onPressed: () => wishlistController.toggleWishlist(widget.product),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    RatingStars(
                      rating: widget.product.rating,
                      size: 16,
                      reviewCount: widget.product.reviewCount,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Category: ${widget.product.category}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                        ),
                        Text(
                          _formatPrice(_effectivePrice),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text('Select Size', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 15,
                      runSpacing: 10,
                      children: _sizeOptions.map((size) {
                        final isSelected = _selectedSize == size;
                        final variant = _hasVariants
                            ? widget.product.variants.firstWhere((v) => v.size == size)
                            : null;
                        final outOfStock = variant != null && variant.stock <= 0;
                        return Semantics(
                          button: true,
                          selected: isSelected,
                          label: outOfStock ? 'Size $size, out of stock' : 'Size $size',
                          child: GestureDetector(
                            onTap: outOfStock ? null : () => setState(() => _selectedSize = size),
                            child: Opacity(
                              opacity: outOfStock ? 0.4 : 1.0,
                              child: Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  size,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : theme.textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    decoration: outOfStock ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_availableStock != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _availableStock! > 0
                            ? (_availableStock! <= 5
                                  ? 'Only $_availableStock left in stock'
                                  : 'In stock')
                            : 'Out of stock',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _availableStock! > 0 ? Colors.green : theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    Text('Description', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Text(
                      widget.product.description,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Text('Shipping & Returns', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Text(
                      'Free shipping on orders over \$100. Easy 30-day returns accepted.',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Text('Reviews', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Obx(() {
                      final reviews = ReviewController.instance.productReviews;
                      if (reviews.isEmpty) {
                        return Text(
                          'No reviews yet — be the first after your order is delivered.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                        );
                      }
                      return Column(
                        children: reviews
                            .map(
                              (review) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          review.userName,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        RatingStars(rating: review.rating, size: 14),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(review.comment, style: theme.textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: _selectionInStock ? _addToCart : null,
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Add To Cart'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _selectionInStock ? _buyNow : null,
                        child: Text(_selectionInStock ? 'Buy Now' : 'Out of Stock'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
