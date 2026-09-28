import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/product_controller.dart';
import '../Controllers/wishlist_controller.dart';
import '../Controllers/category_controller.dart';
import '../Controllers/main_tab_controller.dart';
import '../Utils/app_colors.dart';
import '../routes/app_routes.dart';
import '../Utils/responsive.dart';
import '../widgets/product_card.dart';
import '../widgets/state_views.dart';

class _CarouselSlide {
  const _CarouselSlide(this.title, this.description);
  final String title;
  final String description;
}

const _kCarouselSlides = [
  _CarouselSlide('Elevate Your Everyday Style', 'Up to 40% off curated premium apparel & electronics.'),
  _CarouselSlide('Acoustic Perfection Headphones', 'Experience spatial studio audio with active noise canceling.'),
  _CarouselSlide('Urban Streetwear Capsule 2026', 'Limited run organic cotton hoodies & runner sneakers.'),
];

/// Home is the discovery/landing experience: a promo carousel, a flash
/// coupon alert, category shortcuts, and a "Trending Picks" grid — every
/// category tap and "View All" hands off to the Shopping tab (see
/// MainTabController), which owns search/filtering/pagination over the
/// full catalog.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ProductController _productController = ProductController.instance;
  final WishlistController _wishlistController = WishlistController.instance;
  final CategoryController _categoryController = CategoryController.instance;

  static const int _gridLimit = 8;

  int _carouselIndex = 0;
  Timer? _carouselTimer;
  Timer? _countdownTimer;
  int _dealSeconds = 15155;

  @override
  void initState() {
    super.initState();
    _productController.fetchStorefrontFirstPage();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _carouselIndex = (_carouselIndex + 1) % _kCarouselSlides.length);
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _dealSeconds = _dealSeconds > 0 ? _dealSeconds - 1 : 0);
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _dealTimerText {
    final h = _dealSeconds ~/ 3600;
    final m = (_dealSeconds % 3600) ~/ 60;
    final s = _dealSeconds % 60;
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${pad(h)}:${pad(m)}:${pad(s)}';
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
      final categories = _categoryController.categoryNames;
      final trending = products.take(_gridLimit).toList();

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
                _PromoCarousel(
                  slide: _kCarouselSlides[_carouselIndex],
                  index: _carouselIndex,
                  count: _kCarouselSlides.length,
                  dealTimerText: _dealTimerText,
                  onShop: () => MainTabController.instance.goToShopping(),
                ),
                const SizedBox(height: 14),

                const _FlashCouponAlert(),
                const SizedBox(height: 20),

                if (categories.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FEATURED CATEGORIES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      TextButton(
                        onPressed: () => MainTabController.instance.goToShopping(),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _CategoryPill(
                            label: '✨ All Products',
                            filled: true,
                            onTap: () => MainTabController.instance.goToShopping(),
                          );
                        }
                        final category = categories[index - 1];
                        return _CategoryPill(
                          label: category,
                          filled: false,
                          onTap: () => MainTabController.instance.goToShopping(category: category),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: AppColors.coral, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'TRENDING PICKS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (isLoading && products.isEmpty)
                  const LoadingView()
                else if (error.isNotEmpty && products.isEmpty)
                  ErrorStateView(
                    message: error,
                    onRetry: _productController.fetchStorefrontFirstPage,
                  )
                else if (trending.isEmpty)
                  const EmptyStateView(
                    icon: Icons.storefront_outlined,
                    title: 'No products yet',
                    message: 'Check back soon — new arrivals show up here first.',
                  )
                else
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: trending.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.gridColumns(context),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.66,
                    ),
                    itemBuilder: (context, index) {
                      final product = trending[index];
                      return ProductCard(
                        product: product,
                        onTap: () => _navigateToProductDetails(product),
                        onToggleWishlist: () => _wishlistController.toggleWishlist(product),
                        isWishlisted: _wishlistController.isInWishlist(product.id),
                      );
                    },
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _PromoCarousel extends StatelessWidget {
  const _PromoCarousel({
    required this.slide,
    required this.index,
    required this.count,
    required this.dealTimerText,
    required this.onShop,
  });

  final _CarouselSlide slide;
  final int index;
  final int count;
  final String dealTimerText;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -32,
                  bottom: -32,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SPRING DEAL 2026',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              dealTimerText,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        slide.title,
                        key: ValueKey(slide.title),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      slide.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: onShop,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: const Text('Shop Collection'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            count,
                            (i) => Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == index ? AppColors.coral : Colors.white30,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: null,
                              minHeight: 4,
                              backgroundColor: Colors.black26,
                              valueColor: const AlwaysStoppedAnimation(AppColors.coral),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlashCouponAlert extends StatefulWidget {
  const _FlashCouponAlert();

  @override
  State<_FlashCouponAlert> createState() => _FlashCouponAlertState();
}

class _FlashCouponAlertState extends State<_FlashCouponAlert> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment(-1 - t * 2, 0),
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.bolt, color: Colors.amber, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flash Coupon Active',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text.rich(
                      TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        children: const [
                          TextSpan(text: 'Use code '),
                          TextSpan(
                            text: 'ZENTRA10',
                            style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' for \$10 OFF!'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(30),
          border: filled ? null : Border.all(color: theme.dividerColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: filled ? Colors.white : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}
