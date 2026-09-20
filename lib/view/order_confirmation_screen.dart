import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../routes/app_routes.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final double totalAmount;

  const OrderConfirmationScreen({super.key, required this.totalAmount});

  String _formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 180,
                child: Lottie.asset(
                  'assets/animations/order_success.json',
                  repeat: false,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.check_circle, color: Colors.green, size: 90),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Order Confirmed!',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your order has been placed successfully.\nThank you for shopping with us!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 20),
              Text(
                'Total: ${_formatPrice(totalAmount)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => Get.offAllNamed(AppRoutes.main),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
