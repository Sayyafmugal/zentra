import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/product_controller.dart';
import '../Controllers/wishlist_controller.dart';
import '../Controllers/category_controller.dart';
import '../routes/app_routes.dart';
import '../Utils/responsive.dart';
import '../widgets/product_card.dart';
import '../widgets/state_views.dart';

class ShoppingTab extends StatefulWidget {
  const ShoppingTab({super.key});

  @override
  State<ShoppingTab> createState() => _ShoppingTabState();
}

class _ShoppingTabState extends State<ShoppingTab> {
  final ProductController _productController = ProductController.instance;
  final WishlistController _wishlistController = WishlistController.instance;
  final CategoryController _categoryController = CategoryController.instance;
  final _searchController = TextEditingController();

  int _selectedCategoryIdx = 0;
  String _query = '';
  bool _showSearch = false;

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

  // Search/category filtering happens client-side over whatever's been paged
  // in, so it needs the whole catalog loaded to be correct — this pages in
  // the rest on demand rather than doing that on every cold start, which is
  // the thing storefront pagination exists to avoid.
  void _ensureFullyLoadedIfFiltering(String selectedCategory) {
    if (selectedCategory != 'All' || _query.trim().isNotEmpty) {
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
        ? products
        : products.where((p) => p.category == selectedCategory).toList();
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
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
      final clampedIndex = categories.isEmpty
          ? 0
          : _selectedCategoryIdx.clamp(0, categories.length - 1);
      final selectedCategory = categories.isEmpty ? 'All' : categories[clampedIndex];
      final filtered = _filteredProducts(products, selectedCategory);
      final isFiltering = selectedCategory != 'All' || _query.trim().isNotEmpty;

      return SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _showSearch
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (v) {
                              setState(() => _query = v);
                              _ensureFullyLoadedIfFiltering(selectedCategory);
                            },
                            decoration: const InputDecoration(hintText: 'Search products'),
                          )
                        : Text('Shopping', style: theme.textTheme.titleLarge),
                  ),
                  IconButton(
                    icon: Icon(_showSearch ? Icons.close : Icons.search),
                    onPressed: () => setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _query = '';
                        _searchController.clear();
                      }
                    }),
                  ),
                ],
              ),
            ),

            // Category chips
            SizedBox(
              height: 48,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final selected = index == clampedIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text(categories[index]),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedCategoryIdx = index);
                        _ensureFullyLoadedIfFiltering(categories[index]);
                      },
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(color: selected ? Colors.white : null),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _productController.fetchStorefrontFirstPage,
                child: loading && products.isEmpty
                    ? const LoadingView()
                    : filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          EmptyStateView(icon: Icons.search_off, title: 'No products found'),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: Responsive.gridColumns(context),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.68,
                              ),
                              delegate: SliverChildBuilderDelegate((context, index) {
                                final product = filtered[index];
                                return ProductCard(
                                  product: product,
                                  onTap: () => _onProductTapped(product),
                                  onToggleWishlist: () =>
                                      _wishlistController.toggleWishlist(product),
                                  isWishlisted: _wishlistController.isInWishlist(product.id),
                                );
                              }, childCount: filtered.length),
                            ),
                            if (!isFiltering && hasMore)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: isLoadingMore
                                        ? const CircularProgressIndicator()
                                        : OutlinedButton(
                                            onPressed:
                                                _productController.loadMoreStorefrontProducts,
                                            child: const Text('Load More'),
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
