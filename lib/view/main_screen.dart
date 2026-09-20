import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_screen.dart';
import 'shopping_screen.dart';
import 'wish_list_screen.dart';
import 'account_screen.dart';
import '../Controllers/user_profile_controller.dart';
import '../routes/app_routes.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [HomeTab(), ShoppingTab(), WishlistTab(), AccountTab()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildAppBarTitle(BuildContext context) {
    if (_selectedIndex != 0) return const SizedBox.shrink();

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
    if (_selectedIndex != 0) return [];
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
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              toolbarHeight: 80,
              title: _buildAppBarTitle(context),
              actions: _buildAppBarActions(),
            )
          : null,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Shopping'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Wishlist'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}
