import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_screen.dart';
import 'shopping_screen.dart';
import 'wish_list_screen.dart';
import 'account_screen.dart';
import '../Controllers/main_tab_controller.dart';
import '../Controllers/role_preview_controller.dart';
import '../Controllers/theme_controller.dart';
import '../Controllers/cart_controller.dart';
import '../Controllers/product_controller.dart';
import '../Utils/app_colors.dart';
import '../routes/app_routes.dart';
import '../widgets/cart_drawer.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const _screens = [HomeTab(), ShoppingTab(), WishlistTab(), AccountTab()];

  @override
  Widget build(BuildContext context) {
    final tabController = MainTabController.instance;

    return Obx(() {
      final selectedIndex = tabController.currentIndex.value;
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            const _AppHeader(),
            Expanded(child: IndexedStack(index: selectedIndex, children: _screens)),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: tabController.setIndex,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Shopping'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Wishlist'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Account'),
          ],
        ),
      );
    });
  }
}

/// The persistent teal header shown above every tab: logo + role badge,
/// live search (with an instant suggestions dropdown), a dark-mode toggle,
/// and a cart icon that opens [CartDrawer] — matching the mockup exactly.
class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final rolePreview = RolePreviewController.instance;
    final cartController = CartController.instance;

    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColors.teal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Z',
                style: TextStyle(
                  color: AppColors.coral,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ZENTRA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                Obx(
                  () => Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      rolePreview.previewRole.value.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Expanded(child: _HeaderSearchField()),
            Obx(
              () => IconButton(
                onPressed: themeController.toggleTheme,
                icon: Icon(
                  themeController.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: themeController.isDarkMode ? Colors.amber : Colors.white70,
                  size: 20,
                ),
              ),
            ),
            Obx(
              () => Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => CartDrawer.open(context),
                    icon: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
                  ),
                  if (cartController.totalItems > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.teal, width: 2),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cartController.totalItems}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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

class _HeaderSearchField extends StatefulWidget {
  const _HeaderSearchField();

  @override
  State<_HeaderSearchField> createState() => _HeaderSearchFieldState();
}

class _HeaderSearchFieldState extends State<_HeaderSearchField> {
  final _controller = TextEditingController();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _hideSuggestions();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (value.trim().isEmpty) {
      _hideSuggestions();
    } else {
      _showSuggestions(value.trim());
    }
    setState(() {});
  }

  void _hideSuggestions() {
    _overlay?.remove();
    _overlay = null;
  }

  void _showSuggestions(String query) {
    _hideSuggestions();
    final matches = ProductController.instance.publishedStorefrontProducts
        .where(
          (p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.category.toLowerCase().contains(query.toLowerCase()),
        )
        .take(6)
        .toList();

    _overlay = OverlayEntry(
      builder: (context) => Positioned(
        width: 220,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: matches.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No products found', style: TextStyle(fontSize: 12)),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: matches
                          .map(
                            (p) => ListTile(
                              dense: true,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  p.imagePath,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20),
                                ),
                              ),
                              title: Text(
                                p.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '\$${p.currentPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              onTap: () {
                                _controller.clear();
                                _focusNode.unfocus();
                                _hideSuggestions();
                                Get.toNamed(AppRoutes.productDetails, arguments: p);
                              },
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        height: 34,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 16),
            prefixIconConstraints: const BoxConstraints(minWidth: 32),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 14),
                    onPressed: () {
                      _controller.clear();
                      _hideSuggestions();
                      setState(() {});
                    },
                  )
                : null,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: AppColors.coral, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}
