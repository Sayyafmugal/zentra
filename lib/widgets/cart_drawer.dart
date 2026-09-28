import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/cart_controller.dart';
import '../Controllers/coupon_controller.dart';
import '../Controllers/order_controller.dart';
import '../Controllers/main_tab_controller.dart';
import '../Utils/app_colors.dart';
import '../Utils/pricing_constants.dart';
import '../services/payment_service.dart';
import 'product_image.dart';
import 'quantity_selector.dart';
import 'app_toast.dart';

enum _PaymentChoice { card, cashOnDelivery }

/// The mockup's slide-up "Checkout Cart" drawer — cart items, a coupon
/// field, a price breakdown, a payment method picker, and a single "Place
/// Order" action, all in one sheet instead of separate Cart/Checkout
/// screens. Per the agreed simplification, this skips the shipping-address
/// step the mockup itself never has; everything else (price re-validation,
/// stock checks, coupon redemption, the 11-state order it creates) still
/// goes through the same secure OrderController.createOrderFromCart
/// transaction as before.
class CartDrawer extends StatefulWidget {
  const CartDrawer({super.key});

  static Future<void> open(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CartDrawer(),
    );
  }

  @override
  State<CartDrawer> createState() => _CartDrawerState();
}

class _CartDrawerState extends State<CartDrawer> {
  final _couponController = TextEditingController();
  _PaymentChoice _paymentChoice = _PaymentChoice.card;
  Coupon? _appliedCoupon;
  String? _couponMessage;
  bool _couponValid = false;
  bool _checkingCoupon = false;
  bool _placingOrder = false;
  String? _errorText;

  String _price(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  double _subtotal(List<CartItem> items) =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  Future<void> _applyCoupon(double subtotal) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() => _checkingCoupon = true);
    final coupon = await CouponController.instance.previewCoupon(code, subtotal);
    if (!mounted) return;
    setState(() {
      _checkingCoupon = false;
      _appliedCoupon = coupon;
      _couponValid = coupon != null;
      _couponMessage = coupon != null
          ? '✓ ${_price(coupon.discountFor(subtotal))} Coupon Applied!'
          : '✕ Invalid Coupon Code';
    });
  }

  Future<void> _placeOrder() async {
    setState(() {
      _placingOrder = true;
      _errorText = null;
    });

    final PaymentService service = _paymentChoice == _PaymentChoice.card
        ? DemoCardPaymentService()
        : CashOnDeliveryPaymentService();

    final subtotal = _subtotal(CartController.instance.cartItems);
    final shipping = kFlatShippingFee;
    final tax = (subtotal + shipping) * kTaxRate;
    final discount = _appliedCoupon?.discountFor(subtotal) ?? 0;
    final total = (subtotal + shipping + tax - discount).clamp(0.0, double.infinity);

    final result = await service.charge(amount: total);
    if (!result.success) {
      if (!mounted) return;
      setState(() {
        _placingOrder = false;
        _errorText = result.failureReason ?? 'Payment could not be completed.';
      });
      return;
    }

    final error = await OrderController.instance.createOrderFromCart(
      paymentMethod: service.label,
      paymentStatus: result.resultingStatus,
      couponCode: _appliedCoupon?.id,
    );

    if (!mounted) return;
    setState(() => _placingOrder = false);

    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    Navigator.of(context).pop();
    AppToast.show('Order placed successfully!');
    MainTabController.instance.setIndex(3); // Account tab, matching the mockup
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartController = CartController.instance;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drawer header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Checkout Cart',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Cart items
              Expanded(
                child: Obx(() {
                  final items = cartController.cartItems;
                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Your cart is empty'),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final stock = item.product.stockForSize(item.selectedSize);
                      final canIncrement = stock == null || item.quantity < stock;
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ProductImage(path: item.product.imagePath, width: 44, height: 44),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _price(item.totalPrice),
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            QuantitySelector(
                              quantity: item.quantity,
                              canIncrement: canIncrement,
                              onIncrement: () => cartController.updateCartItemQuantity(
                                item.id,
                                item.quantity + 1,
                              ),
                              onDecrement: () => cartController.updateCartItemQuantity(
                                item.id,
                                item.quantity - 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),

              // Summary footer
              Obx(() {
                final items = cartController.cartItems;
                final subtotal = _subtotal(items);
                final shipping = items.isEmpty ? 0.0 : kFlatShippingFee;
                final tax = items.isEmpty ? 0.0 : (subtotal + shipping) * kTaxRate;
                final discount = _appliedCoupon?.discountFor(subtotal) ?? 0;
                final total = (subtotal + shipping + tax - discount).clamp(0.0, double.infinity);
                final opacity = items.isEmpty ? 0.5 : 1.0;

                return IgnorePointer(
                  ignoring: items.isEmpty,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                  decoration: const InputDecoration(
                                    hintText: 'Coupon (e.g. ZENTRA10)',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _checkingCoupon ? null : () => _applyCoupon(subtotal),
                                child: _checkingCoupon
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Apply'),
                              ),
                            ],
                          ),
                          if (_couponMessage != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _couponMessage!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _couponValid ? AppColors.success : AppColors.coral,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _SummaryRow('Subtotal', _price(subtotal)),
                          _SummaryRow('Shipping', _price(shipping)),
                          _SummaryRow('Tax', _price(tax)),
                          _SummaryRow('Discount', '-${_price(discount)}', color: AppColors.coral),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: theme.dividerColor),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                _price(total.toDouble()),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'PAYMENT OPTION',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.hintColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _PaymentTile(
                                  label: 'Pay with Card',
                                  selected: _paymentChoice == _PaymentChoice.card,
                                  onTap: () => setState(() => _paymentChoice = _PaymentChoice.card),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _PaymentTile(
                                  label: 'Cash on Delivery',
                                  selected: _paymentChoice == _PaymentChoice.cashOnDelivery,
                                  onTap: () =>
                                      setState(() => _paymentChoice = _PaymentChoice.cashOnDelivery),
                                ),
                              ),
                            ],
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _errorText!,
                              style: const TextStyle(color: AppColors.error, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _placingOrder ? null : _placeOrder,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
                              icon: _placingOrder
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.lock_outline, size: 16),
                              label: const Text('Place Order & Authorize'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.dividerColor,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 16,
              color: selected ? theme.colorScheme.primary : theme.hintColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
