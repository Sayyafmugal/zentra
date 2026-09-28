import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Utils/app_colors.dart';

/// The floating teal pill toast from the mockup ("Item moved to cart" with
/// an optional coral "Undo" action) — used for cart/wishlist feedback
/// instead of a plain SnackBar, matching its exact look.
class AppToast {
  AppToast._();

  static void show(String message, {VoidCallback? onUndo}) {
    Get.rawSnackbar(
      messageText: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          if (onUndo != null)
            TextButton(
              onPressed: () {
                onUndo();
                Get.closeCurrentSnackbar();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.amber),
              child: const Text('Undo', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      backgroundColor: AppColors.teal,
      borderRadius: 16,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 90),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      snackStyle: SnackStyle.FLOATING,
      animationDuration: const Duration(milliseconds: 250),
    );
  }
}
