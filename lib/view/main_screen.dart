import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_screen.dart';
import 'shopping_screen.dart';
import 'wish_list_screen.dart';
import 'account_screen.dart';
import '../Controllers/user_profile_controller.dart';
import '../Controllers/main_tab_controller.dart';
import '../routes/app_routes.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const _screens = [HomeTab(), ShoppingTab(), WishlistTab(), AccountTab()];

  Widget _buildAppBarTitle(BuildContext context) {
    final profileController = UserProfileController.instance;
    return Obx(() {
      final name = profileController.currentProfile.value?.fullName.split(' ').first ?? 'there';
      return Row(
        children: [
          const CircleAvatar(radius: 24, backgroundImage: AssetImage('assets/images/avaatr1.png')),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello $name', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                'Good Morning!',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      );
    });
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.notifications_none, size: 28),
        onPressed: () => Get.toNamed(AppRoutes.notifications),
      ),
      IconButton(
        icon: const Icon(Icons.shopping_bag_outlined, size: 28),
        onPressed: () => Get.toNamed(AppRoutes.cart),
      ),
      const SizedBox(width: 8),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabController = MainTabController.instance;

    return Obx(() {
      final selectedIndex = tabController.currentIndex.value;
      return Scaffold(
        appBar: selectedIndex == 0
            ? AppBar(
                toolbarHeight: 80,
                title: _buildAppBarTitle(context),
                actions: _buildAppBarActions(),
              )
            : null,
        body: IndexedStack(index: selectedIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: tabController.setIndex,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Shopping'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Wishlist'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
          ],
        ),
      );
    });
  }
}
