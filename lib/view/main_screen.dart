import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'Shopping_screen.dart';      // tab: ShoppingTab
import 'my_cart_screen.dart';      // push: MyCartScreen (top cart button)
import 'Wish_list_screen.dart';
import 'Account_screen.dart';
import 'notifications_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const Color primaryColor = Color(0xFFFF5200);

  // The list of the four primary screens (tabs)
  final List<Widget> _screens = [
    const HomeTab(),     // 0: Dedicated Home Tab
    const ShoppingTab(), // 1: Shopping Bag Tab
    const WishlistTab(), // 2: Wishlist Tab
    const AccountTab(),  // 3: Account Tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  // Top AppBar cart button -> open MyCartScreen
  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyCartScreen(),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    if (_selectedIndex == 0) {
      return Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage('assets/images/avaatr1.png'),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Hello Sayyaf', style: TextStyle(color: Colors.black, fontSize: 16)),
              Text('Good Morning!', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  List<Widget> _buildAppBarActions() {
    if (_selectedIndex == 0) {
      return [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28),
          onPressed: _navigateToNotifications,
        ),
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black, size: 28),
          onPressed: _navigateToCart,
        ),
        const SizedBox(width: 8),
      ];
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        title: _buildAppBarTitle(),
        actions: _buildAppBarActions(),
      )
          : null,

      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
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