import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/product_controller.dart';
import '../Controllers/wishlist_controller.dart';
import '../Controllers/category_controller.dart';
import '../Controllers/cart_controller.dart';
import '../Controllers/main_tab_controller.dart';
import '../Utils/app_colors.dart';
import '../routes/app_routes.dart';
import '../widgets/product_image.dart';
import '../widgets/rating_stars.dart';
import '../widgets/state_views.dart';
import '../widgets/app_toast.dart';

enum _SortOption { featured, lowHigh, highLow, rating }

/// The full catalog — a left category rail plus a scrollable product list
/// on the right, matching the mockup's split-view Shopping tab. There's no
/// search field here: in the mockup, search lives only in the persistent
/// header as a "jump straight to a product" suggestions dropdown, not a
/// live filter over this list.
class ShoppingTab extends StatefulWidget {
  const ShoppingTab({super.key});

  @override
  State<ShoppingTab> createState() => _ShoppingTabState();
}

class _ShoppingTabState extends State<ShoppingTab> {
  final ProductController _productController = ProductController.instance;
  final WishlistController _wishlistController = WishlistController.instance;
  final CategoryController _categoryController = CategoryController.instance;

  int _selectedCategoryIdx = 0;
  _SortOption _sort = _SortOption.featured;
  String? _pendingCategory;

  @override
  void initState() {
    super.initState();
    _productController.fetchStorefrontFirstPage();
    // Arrived here via Home's "View All" / a category tap — consume the
    // request once; a plain re-visit of the Shopping tab afterward keeps
    // whatever the user picks here instead of re-applying a stale filter.
    final tabController = MainTabController.instance;
    final pending = tabController.pendingShoppingCategory.value;
    if (pending.isNotEmpty) {
      _pendingCategory = pending;
      tabController.pendingShoppingCategory.value = '';
    }
  }

  // Category filtering happens client-side over whatever's been paged in, so
  // it needs the whole catalog loaded to be correct — this pages in the
  // rest on demand rather than doing that on every cold start, which is the
  // thing storefront pagination exists to avoid.
  void _ensureFullyLoadedIfFiltering(String selectedCategory) {
    if (selectedCategory != 'All') {
      _productController.ensureStorefrontFullyLoaded();
    }
  }

  void _onProductTapped(Product product) {
    Get.toNamed(AppRoutes.productDetails, arguments: product);
  }

  // Sourced from the real, admin-managed categories collection rather than
  // scanned from whatever products happen to be paged in — the latter would
  // silently hide a category until enough pages loaded to include one of
  // its products (see ProductController's storefront pagination).
  List<String> _computeCategories() {
    return ['All', ..._categoryController.categoryNames];
  }

  List<Product> _filteredProducts(List<Product> products, String selectedCategory) {
    var list = selectedCategory == 'All'
        ? [...products]
        : products.where((p) => p.category == selectedCategory).toList();
    switch (_sort) {
      case _SortOption.lowHigh:
        list.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
      case _SortOption.highLow:
        list.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
      case _SortOption.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortOption.featured:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final products = _productController.publishedStorefrontProducts;
      final loading = _productController.isLoading.value;
      final hasMore = _productController.hasMoreStorefront.value;
      final isLoadingMore = _productController.isLoadingMoreStorefront.value;

      final categories = _computeCategories();
      if (_pendingCategory != null && categories.contains(_pendingCategory)) {
        _selectedCategoryIdx = categories.indexOf(_pendingCategory!);
        _ensureFullyLoadedIfFiltering(_pendingCategory!);
        _pendingCategory = null;
      }
      final clampedIndex = categories.isEmpty
          ? 0
          : _selectedCategoryIdx.clamp(0, categories.length - 1);
      final selectedCategory = categories.isEmpty ? 'All' : categories[clampedIndex];
      final filtered = _filteredProducts(products, selectedCategory);
      final isFiltering = selectedCategory != 'All';

      return Column(
        children: [
          // Results bar: count + sort
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} Products',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.hintColor,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<_SortOption>(
                    value: _sort,
                    isDense: true,
                    borderRadius: BorderRadius.circular(12),
                    style: theme.textTheme.bodySmall,
                    onChanged: (v) => setState(() => _sort = v ?? _SortOption.featured),
                    items: const [
                      DropdownMenuItem(value: _SortOption.featured, child: Text('Featured')),
                      DropdownMenuItem(
                        value: _SortOption.lowHigh,
                        child: Text('Price: Low to High'),
                      ),
                      DropdownMenuItem(
                        value: _SortOption.highLow,
                        child: Text('Price: High to Low'),
                      ),
                      DropdownMenuItem(value: _SortOption.rating, child: Text('Top Rated')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Split view: category rail + product list
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CategoryRail(
                  categories: categories,
                  selectedIndex: clampedIndex,
                  onSelect: (index) {
                    setState(() => _selectedCategoryIdx = index);
                    _ensureFullyLoadedIfFiltering(categories[index]);
                  },
                ),
                Expanded(
                  child: loading && products.isEmpty
                      ? const LoadingView(asGrid: false)
                      : filtered.isEmpty
                      ? const EmptyStateView(icon: Icons.search_off, title: 'No products found')
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == filtered.length) {
                              if (isFiltering || !hasMore) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: isLoadingMore
                                      ? const CircularProgressIndicator()
                                      : OutlinedButton.icon(
                                          onPressed: _productController.loadMoreStorefrontProducts,
                                          icon: const Icon(Icons.expand_more, size: 16),
                                          label: const Text('Load More Products'),
                                        ),
                                ),
                              );
                            }
                            final product = filtered[index];
                            return _ShoppingProductRow(
                              product: product,
                              isWishlisted: _wishlistController.isInWishlist(product.id),
                              onTap: () => _onProductTapped(product),
                              onToggleWishlist: () => _wishlistController.toggleWishlist(product),
                              onAdd: () {
                                CartController.instance.addToCart(
                                  product: product,
                                  selectedSize: product.availableSizes.isNotEmpty
                                      ? product.availableSizes.first
                                      : 'One Size',
                                );
                                AppToast.show('Added "${product.name}" to cart');
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 84,
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return InkWell(
            onTap: () => onSelect(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: selected ? theme.colorScheme.primary : Colors.transparent,
                    width: 4,
                  ),
                ),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected ? theme.colorScheme.primary : theme.hintColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShoppingProductRow extends StatelessWidget {
  const _ShoppingProductRow({
    required this.product,
    required this.isWishlisted,
    required this.onTap,
    required this.onToggleWishlist,
    required this.onAdd,
  });

  final Product product;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onToggleWishlist;
  final VoidCallback onAdd;

  String _price(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ProductImage(path: product.imagePath, width: 80, height: 80),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Material(
                    color: theme.cardColor,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onToggleWishlist,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 12,
                          color: isWishlisted ? AppColors.coral : theme.hintColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      RatingStars(rating: product.rating, size: 11),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _price(product.currentPrice),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: product.isInStock ? onAdd : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            minimumSize: const Size(0, 30),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          child: Text(product.isInStock ? 'Add' : 'Sold Out'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
