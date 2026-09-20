import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/order_controller.dart';
import '../Controllers/address_controller.dart';
import '../Controllers/payment_method_controller.dart';
import '../Controllers/coupon_controller.dart';
import '../Utils/pricing_constants.dart';
import '../routes/app_routes.dart';
import '../services/payment_service.dart';

enum _PaymentChoice { cashOnDelivery, demoCard }

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;
  final int itemCount;

  const CheckoutScreen({super.key, required this.totalAmount, required this.itemCount});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _placingOrder = false;
  bool _checkingCoupon = false;
  String? _couponError;
  Coupon? _appliedCoupon;
  final _couponController = TextEditingController();
  // Cash on Delivery needs no saved card, so it's the sensible default — a
  // customer who's never added a card can still complete checkout.
  _PaymentChoice _paymentChoice = _PaymentChoice.cashOnDelivery;

  double get _subtotal => widget.totalAmount;
  double get _shipping => kFlatShippingFee;
  double get _tax => (_subtotal + _shipping) * kTaxRate;
  double get _discount => _appliedCoupon?.discountFor(_subtotal) ?? 0;
  double get _total => (_subtotal + _shipping + _tax - _discount).clamp(0, double.infinity);

  String _formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  // This is only a preview so the customer sees the discount before placing
  // the order — the coupon is re-validated (existence, expiry, usage limit,
  // per-user reuse) from scratch inside the checkout transaction, so a stale
  // or bypassed preview can never make it into the actual order.
  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _checkingCoupon = true;
      _couponError = null;
    });

    final coupon = await CouponController.instance.previewCoupon(code, _subtotal);

    if (!mounted) return;
    setState(() {
      _checkingCoupon = false;
      _appliedCoupon = coupon;
      _couponError = coupon == null ? 'This code isn\'t valid for your order.' : null;
    });
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponError = null;
      _couponController.clear();
    });
  }

  PaymentService _serviceFor(_PaymentChoice choice) => switch (choice) {
    _PaymentChoice.cashOnDelivery => CashOnDeliveryPaymentService(),
    _PaymentChoice.demoCard => DemoCardPaymentService(),
  };

  Future<void> _placeOrder({required String shippingAddress, String? cardLabel}) async {
    setState(() => _placingOrder = true);

    final service = _serviceFor(_paymentChoice);
    final result = await service.charge(amount: _total);

    if (!result.success) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      return;
    }

    final paymentMethod = _paymentChoice == _PaymentChoice.cashOnDelivery
        ? service.label
        : '${service.label}${cardLabel != null ? ' · $cardLabel' : ''}';

    final error = await OrderController.instance.createOrderFromCart(
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      paymentStatus: result.resultingStatus,
      couponCode: _appliedCoupon?.id,
    );

    if (!mounted) return;
    setState(() => _placingOrder = false);

    if (error != null) {
      return;
    }

    Get.offNamed(AppRoutes.orderConfirmation, arguments: _total);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addressController = AddressController.instance;
    final paymentController = PaymentMethodController.instance;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        title: const Text('Checkout'),
      ),
      body: Obx(() {
        final defaultAddress = addressController.defaultAddress;
        final defaultPayment = paymentController.defaultPaymentMethod;
        final needsCard = _paymentChoice == _PaymentChoice.demoCard;
        final canPlaceOrder = defaultAddress != null && (!needsCard || defaultPayment != null);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shipping Address', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    defaultAddress != null
                        ? _InfoCard(
                            icon: Icons.location_on,
                            iconColor: Colors.red,
                            title: defaultAddress.fullName,
                            subtitle: defaultAddress.fullAddress,
                            onEdit: () => Get.toNamed(AppRoutes.shippingAddress),
                          )
                        : _MissingInfoCard(
                            icon: Icons.location_on_outlined,
                            message: 'No shipping address saved yet.',
                            ctaLabel: 'Add address',
                            onTap: () => Get.toNamed(AppRoutes.shippingAddress),
                          ),
                    const SizedBox(height: 24),

                    Text('Payment Method', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _PaymentOptionTile(
                      icon: Icons.local_shipping_outlined,
                      title: 'Cash on Delivery',
                      subtitle: 'Pay with cash when your order arrives.',
                      selected: _paymentChoice == _PaymentChoice.cashOnDelivery,
                      onTap: () => setState(() => _paymentChoice = _PaymentChoice.cashOnDelivery),
                    ),
                    const SizedBox(height: 8),
                    _PaymentOptionTile(
                      icon: Icons.credit_card,
                      title: 'Pay with Card',
                      subtitle: 'Demo only — no real charge is made.',
                      selected: _paymentChoice == _PaymentChoice.demoCard,
                      onTap: () => setState(() => _paymentChoice = _PaymentChoice.demoCard),
                    ),
                    if (_paymentChoice == _PaymentChoice.demoCard) ...[
                      const SizedBox(height: 8),
                      defaultPayment != null
                          ? _InfoCard(
                              icon: Icons.credit_card,
                              iconColor: Colors.blue,
                              title: defaultPayment.displayName,
                              subtitle: defaultPayment.maskedCardNumber,
                              onEdit: () => Get.toNamed(AppRoutes.paymentMethod),
                            )
                          : _MissingInfoCard(
                              icon: Icons.credit_card_outlined,
                              message: 'No saved card yet.',
                              ctaLabel: 'Add a demo card',
                              onTap: () => Get.toNamed(AppRoutes.paymentMethod),
                            ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No real payment provider is configured. This card charge is '
                                'simulated for demo purposes only.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    Text('Coupon Code', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_appliedCoupon != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_appliedCoupon!.id} applied — '
                                '${_formatPrice(_discount)} off',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(onPressed: _removeCoupon, child: const Text('Remove')),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'Enter coupon code',
                                errorText: _couponError,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _checkingCoupon ? null : _applyCoupon,
                              child: _checkingCoupon
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),

                    Text('Order Summary', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _PriceRow(label: 'Subtotal', price: _formatPrice(_subtotal)),
                          _PriceRow(label: 'Shipping', price: _formatPrice(_shipping)),
                          _PriceRow(label: 'Tax', price: _formatPrice(_tax)),
                          if (_appliedCoupon != null)
                            _PriceRow(
                              label: 'Discount (${_appliedCoupon!.id})',
                              price: '-${_formatPrice(_discount)}',
                            ),
                          const Divider(height: 24, thickness: 1),
                          _PriceRow(label: 'Total', price: _formatPrice(_total), isTotal: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: !canPlaceOrder || _placingOrder
                        ? null
                        : () => _placeOrder(
                            shippingAddress: defaultAddress.fullAddress,
                            cardLabel: needsCard
                                ? '${defaultPayment!.displayName} (${defaultPayment.maskedCardNumber})'
                                : null,
                          ),
                    child: _placingOrder
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            canPlaceOrder
                                ? 'Place Order (${_formatPrice(_total)})'
                                : defaultAddress == null
                                ? 'Add a shipping address to continue'
                                : 'Add a card to continue',
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onEdit,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, height: 1.3),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
    );
  }
}

class _MissingInfoCard extends StatelessWidget {
  const _MissingInfoCard({
    required this.icon,
    required this.message,
    required this.ctaLabel,
    required this.onTap,
  });

  final IconData icon;
  final String message;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
          TextButton(onPressed: onTap, child: Text(ctaLabel)),
        ],
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? theme.colorScheme.primary : theme.hintColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? theme.colorScheme.primary : theme.hintColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.price, this.isTotal = false});

  final String label;
  final String price;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = isTotal
        ? theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          )
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(price, style: style),
        ],
      ),
    );
  }
}
