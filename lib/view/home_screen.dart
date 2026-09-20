import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/product_controller.dart';
import '../Controllers/wishlist_controller.dart';
import '../Controllers/category_controller.dart';
import '../routes/app_routes.dart';
import '../Utils/responsive.dart';
import '../widgets/product_card.dart';
import '../widgets/state_views.dart';
import '../widgets/section_header.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ProductController _productController = ProductController.instance;
  final WishlistController _wishlistController = WishlistController.instance;
  final CategoryController _categoryController = CategoryController.instance;
  final _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _productController.fetchStorefrontFirstPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isFiltering => _selectedCategory != 'All' || _query.trim().isNotEmpty;

  // Search/category filtering happens client-side over whatever's been
  // paged in (see _filtered below), so it needs the whole catalog loaded to
  // be correct — this pages in the rest on demand instead of doing that on
  // every cold start, which is the thing storefront pagination exists to
  // avoid. Cheap to call repeatedly: it's a no-op once everything's loaded.
  void _ensureFullyLoadedIfFiltering() {
    if (_isFiltering) _productController.ensureStorefrontFullyLoaded();
  }

  // Sourced from the real, admin-managed categories collection rather than
  // scanned from whatever products happen to be paged in — the latter would
  // silently hide a category until enough pages loaded to include one of
  // its products (see ProductController's storefront pagination).
  List<String> _buildCategories() {
    return ['All', ..._categoryController.categoryNames];
  }

  List<Product> _filtered(List<Product> products) {
    var list = _selectedCategory == 'All'
        ? products
        : products.where((p) => p.category == _selectedCategory).toList();
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _navigateToProductDetails(Product product) {
    Get.toNamed(AppRoutes.productDetails, arguments: product);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final products = _productController.publishedStorefrontProducts;
      final isLoading = _productController.isLoading.value;
      final error = _productController.errorMessage.value;
      final categories = _buildCategories();
      final filtered = _filtered(products);
      final hasMore = _productController.hasMoreStorefront.value;
      final isLoadingMore = _productController.isLoadingMoreStorefront.value;

      return RefreshIndicator(
        onRefresh: _productController.fetchStorefrontFirstPage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.isDesktop(context) ? 32 : 16,
            vertical: 16,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Responsive.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) {
                          setState(() => _query = v);
                          _ensureFullyLoadedIfFiltering();
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search products',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune, color: Colors.white),
                        tooltip: 'Filter by category',
                        onPressed: () => _showCategoryPicker(context, categories),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: categories
                        .map(
                          (cat) => _CategoryChip(
                            label: cat,
                            selected: _selectedCategory == cat,
                            onTap: () {
                              setState(() => _selectedCategory = cat);
                              _ensureFullyLoadedIfFiltering();
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Banner
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Get Your', style: TextStyle(color: Colors.white, fontSize: 16)),
                          Text(
                            'Special Sale',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          Text('Up to 40%', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() => _selectedCategory = 'All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                        ),
                        child: const Text('Shop Now'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SectionHeader(
                  title: 'Products',
                  actionLabel: _selectedCategory == 'All' ? null : 'See All',
                  onAction: () => setState(() => _selectedCategory = 'All'),
                ),
                const SizedBox(height: 16),

                if (isLoading && products.isEmpty)
                  const LoadingView()
                else if (error.isNotEmpty && products.isEmpty)
                  ErrorStateView(
                    message: error,
                    onRetry: _productController.fetchStorefrontFirstPage,
                  )
                else if (filtered.isEmpty)
                  const EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No products found',
                    message: 'Try a different search term or category.',
                  )
                else ...[
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.gridColumns(context),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.66,
                    ),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ProductCard(
                        product: product,
                        onTap: () => _navigateToProductDetails(product),
                        onToggleWishlist: () => _wishlistController.toggleWishlist(product),
                        isWishlisted: _wishlistController.isInWishlist(product.id),
                      );
                    },
                  ),
                  if (!_isFiltering && hasMore) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: isLoadingMore
                          ? const CircularProgressIndicator()
                          : OutlinedButton(
                              onPressed: _productController.loadMoreStorefrontProducts,
                              child: const Text('Load More'),
                            ),
                    ),
                  ],
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showCategoryPicker(BuildContext context, List<String> categories) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: categories
              .map(
                (cat) => ListTile(
                  title: Text(cat),
                  trailing: _selectedCategory == cat ? const Icon(Icons.check) : null,
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    _ensureFullyLoadedIfFiltering();
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primary,
        labelStyle: TextStyle(color: selected ? Colors.white : null),
      ),
    );
  }
}
