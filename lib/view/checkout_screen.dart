import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/order_controller.dart';
import '../Controllers/address_controller.dart';
import '../Controllers/payment_method_controller.dart';
import 'package:zentra_0/view/payment_method_screen.dart';
import 'order_confirmation_screen.dart'; // Import the confirmation screen
import 'shipping_address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;
  final int itemCount;

  const CheckoutScreen({
    super.key,
    required this.totalAmount,
    required this.itemCount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color primaryColor = Color(0xFFFF5200);

  final String _shippingAddress = "123 Main Street, Apt 4B\nNew York, NY 10001";
  final String _paymentMethod = "Visa ending in 4242";
  final String _expiryDate = "Expires 12/24";

  double get _subtotal => widget.totalAmount;
  double get _shipping => 10.00;
  double get _tax => (_subtotal + _shipping) * 0.08; // 8% tax
  double get _total => _subtotal + _shipping + _tax;

  String _formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

  Future<void> _placeOrder() async {
    final orderController = OrderController.instance;
    final addressController = AddressController.instance;
    final paymentController = PaymentMethodController.instance;

    // Use default address/payment if available, otherwise fall back to text
    final defaultAddress = addressController.defaultAddress;
    final defaultPayment = paymentController.defaultPaymentMethod;

    final shippingAddress =
        defaultAddress != null ? defaultAddress.fullAddress : _shippingAddress;
    final paymentMethod = defaultPayment != null
        ? '${defaultPayment.displayName} (${defaultPayment.maskedCardNumber})'
        : _paymentMethod;

    final error = await orderController.createOrderFromCart(
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
    );

    if (error != null) {
      Get.snackbar(
        'Order Failed',
        error,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Navigate to confirmation screen on success
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          totalAmount: _total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Shipping Address'),
                  const SizedBox(height: 8),
                  _buildAddressCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Payment Method'),
                  const SizedBox(height: 8),
                  _buildPaymentCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Order Summary'),
                  const SizedBox(height: 8),
                  _buildOrderSummaryCard(),
                ],
              ),
            ),
          ),

          // Place Order Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Place Order (${_formatPrice(_total)})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(
    title,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  );

  Widget _buildAddressCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.location_on, color: Colors.red),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _shippingAddress,
            style: const TextStyle(color: Colors.grey, height: 1.3),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShippingAddressScreen()),
            );
          },
          icon: const Icon(Icons.edit, color: Colors.red),
        ),
      ],
    ),
  );

  Widget _buildPaymentCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.credit_card, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_expiryDate, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentMethodScreen()),
            );
          },
          icon: const Icon(Icons.edit, color: Colors.red),
        ),

      ],
    ),
  );

  Widget _buildOrderSummaryCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        _buildPriceRow('Subtotal', _formatPrice(_subtotal)),
        _buildPriceRow('Shipping', _formatPrice(_shipping)),
        _buildPriceRow('Tax', _formatPrice(_tax)),
        const Divider(height: 24, thickness: 1),
        _buildPriceRow('Total', _formatPrice(_total), isTotal: true),
      ],
    ),
  );

  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? primaryColor : Colors.black,
        ),
      ),
      Text(
        price,
        style: TextStyle(
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? primaryColor : Colors.black,
        ),
      ),
    ],
  );
}
