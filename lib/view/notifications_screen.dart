
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color primaryColor = Color(0xFFFF5200);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
            child: const Text(
              'Mark all as read',
              style: TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNotificationCard(
            icon: Icons.shopping_bag_outlined,
            iconColor: primaryColor,
            iconBackgroundColor: primaryColor.withOpacity(0.12),
            title: 'Order Confirmed!',
            body: 'Your order #12345 has been confirmed and is being processed.',
            time: '2 minutes ago',
            isHighlighted: true,
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.local_offer_outlined,
            iconColor: const Color(0xFFFFB800),
            iconBackgroundColor: const Color(0xFFFFB800).withOpacity(0.12),
            title: 'Special Offer!',
            body: 'Get 20% off on all shoes this weekend!',
            time: '1 hour ago',
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.local_shipping_outlined,
            iconColor: const Color(0xFF4CAF50),
            iconBackgroundColor: const Color(0xFF4CAF50).withOpacity(0.12),
            title: 'Out for Delivery',
            body: 'Your order #12344 is out for delivery.',
            time: '3 hours ago',
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.credit_card_outlined,
            iconColor: const Color(0xFFE91E63),
            iconBackgroundColor: const Color(0xFFE91E63).withOpacity(0.12),
            title: 'Payment Successful',
            body: 'Payment for order #12345 was successful.',
            time: '5 hours ago',
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.favorite_outline,
            iconColor: const Color(0xFF9C27B0),
            iconBackgroundColor: const Color(0xFF9C27B0).withOpacity(0.12),
            title: 'Item Back in Stock',
            body: 'The item you saved is now available again!',
            time: '1 day ago',
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.star_outline,
            iconColor: const Color(0xFFFF9800),
            iconBackgroundColor: const Color(0xFFFF9800).withOpacity(0.12),
            title: 'Review Your Purchase',
            body: 'How was your recent order? Leave a review!',
            time: '2 days ago',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required String title,
    required String body,
    required String time,
    bool isHighlighted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isHighlighted ? primaryColor.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isHighlighted)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}