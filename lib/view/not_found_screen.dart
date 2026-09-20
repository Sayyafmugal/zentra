import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';

/// Shown when Flutter Web resolves a URL that isn't in [AppPages] — for
/// example a stale deep link or a manual refresh mid-navigation — instead
/// of crashing with an unresolved-route error.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore_off_outlined, size: 64, color: Theme.of(context).hintColor),
              const SizedBox(height: 16),
              Text('Page not found', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                "The page you're looking for doesn't exist.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.offAllNamed(AppRoutes.main),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
