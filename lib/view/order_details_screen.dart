import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../Controllers/order_controller.dart';
import '../Controllers/review_controller.dart';
import '../Controllers/user_profile_controller.dart';
import '../widgets/product_image.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final Order order;

  String _formatDate(DateTime date) => DateFormat('MMM dd, yyyy • hh:mm a').format(date);

  String _formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

  Future<void> _writeReview(BuildContext context, String productId, String productName) async {
    double rating = 5;
    final commentCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text('Review $productName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starValue = i + 1;
                  return IconButton(
                    icon: Icon(
                      starValue <= rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => rating = starValue.toDouble()),
                  );
                }),
              ),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Share your experience...'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !context.mounted) return;

    final profile = UserProfileController.instance.currentProfile.value;
    await ReviewController.instance.submitReview(
      orderId: order.id,
      productId: productId,
      userName: profile?.fullName ?? 'Anonymous',
      rating: rating,
      comment: commentCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        title: Text('Order #${order.id.substring(0, order.id.length >= 8 ? 8 : order.id.length)}'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: order.statusColor),
                      const SizedBox(width: 6),
                      Text(
                        order.statusString,
                        style: TextStyle(
                          color: order.statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(order.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text('Shipping Address', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _InfoCard(
              icon: Icons.location_on,
              iconColor: Colors.red,
              text: order.shippingAddress ?? 'Not specified',
            ),
            const SizedBox(height: 16),

            Text('Payment Method', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _InfoCard(
              icon: Icons.credit_card,
              iconColor: Colors.blue,
              text: order.paymentMethod ?? 'Not specified',
            ),
            const SizedBox(height: 20),

            Text('Items', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...order.items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ProductImage(path: item.imagePath, width: 60, height: 60),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Size: ${item.selectedSize}  •  Qty: ${item.quantity}',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatPrice(item.price * item.quantity),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (order.status == OrderStatus.delivered) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _writeReview(context, item.productId, item.productName),
                          icon: const Icon(Icons.rate_review_outlined, size: 16),
                          label: const Text('Write a Review'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            Text('Order Summary', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Subtotal', value: _formatPrice(order.subtotal)),
                  const SizedBox(height: 4),
                  _SummaryRow(label: 'Shipping', value: _formatPrice(order.shippingFee)),
                  const SizedBox(height: 4),
                  _SummaryRow(label: 'Tax', value: _formatPrice(order.taxAmount)),
                  if (order.discountAmount > 0) ...[
                    const SizedBox(height: 4),
                    _SummaryRow(
                      label: order.couponId != null
                          ? 'Discount (${order.couponId})'
                          : 'Discount',
                      value: '-${_formatPrice(order.discountAmount)}',
                    ),
                  ],
                  const Divider(height: 20),
                  _SummaryRow(label: 'Total', value: _formatPrice(order.totalAmount)),
                  const SizedBox(height: 4),
                  _SummaryRow(label: 'Status', value: order.statusString),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.iconColor, required this.text});

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4))),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
