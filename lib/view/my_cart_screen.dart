import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/cart_controller.dart';
import 'checkout_screen.dart';

class MyCartScreen extends StatelessWidget {
  const MyCartScreen({super.key});

  static const Color primaryColor = Color(0xFFFF5200);

  String _formatPrice(double v) => '\$${v.toStringAsFixed(2)}';

  void _checkout(CartController cartController) {
    if (cartController.cartItems.isEmpty) {
      Get.snackbar('Empty Cart', 'Your cart is empty');
      return;
    }
    Get.to(() => CheckoutScreen(
      totalAmount: cartController.totalPrice,
      itemCount: cartController.totalItems,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cartController = CartController.instance;

    // Fetch cart items on first load
    if (cartController.cartItems.isEmpty && !cartController.isLoading.value) {
      cartController.fetchCartItems();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'My Cart',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        if (cartController.isLoading.value && cartController.cartItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (cartController.cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Your cart is empty',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: cartController.cartItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = cartController.cartItems[index];
                  return _CartRow(
                    item: item,
                    onRemove: () => cartController.removeFromCart(item.id),
                    onMinus: () => cartController.updateCartItemQuantity(item.id, item.quantity - 1),
                    onPlus: () => cartController.updateCartItemQuantity(item.id, item.quantity + 1),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total (${cartController.totalItems} items)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          _formatPrice(cartController.totalPrice),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _checkout(cartController),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Proceed to Checkout',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.onRemove,
    required this.onMinus,
    required this.onPlus,
  });

  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  static const Color primaryColor = Color(0xFFFF5200);

  String _price(double v) => '\$${v.toStringAsFixed(1)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item.product.imagePath,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 88,
                height: 88,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  _price(item.product.currentPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          // Delete
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: Color(0xFFCC4B4B)),
            tooltip: 'Remove',
          ),
          // Qty stepper
          const SizedBox(width: 4),
          Container(
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onMinus,
                  icon: const Icon(Icons.remove),
                  color: primaryColor,
                  splashRadius: 18,
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: onPlus,
                  icon: const Icon(Icons.add),
                  color: primaryColor,
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
