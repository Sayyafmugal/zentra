import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zentra_0/Controllers/auth_controller.dart';
import 'package:zentra_0/Utils/app_textstyles.dart';
import 'package:zentra_0/routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pageController = PageController();

  int currentPage = 0;
  final List<OnboardingItem> _items = [
    OnboardingItem(
      description: 'Explore the newest fashion trends and find your unique style',
      title: 'Discover latest trends',
      image: 'assets/images/intro.png',
    ),

    OnboardingItem(
      description: 'Shop premium quality products from top brands worldwide',
      title: 'Quality Products',
      image: 'assets/images/intro1.png',
    ),
    OnboardingItem(
      description: 'Simple and Secure shopping experience at your fingertips',
      title: 'Easy Shopping',
      image: 'assets/images/intro2.png',
    ),
  ];

  void handleGetStarted() {
    final AuthController authController = Get.find<AuthController>();
    authController.setFirstTimeDone();
    Get.offNamed(AppRoutes.signin);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: _items.length,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    _items[index].image,
                    height: MediaQuery.of(context).size.height * 0.4,
                  ),

                  const SizedBox(height: 40),
                  Text(
                    _items[index].title,
                    style: AppTextStyles.withColor(
                      AppTextStyles.h1,
                      Theme.of(context).textTheme.bodyLarge!.color!,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _items[index].description,
                      style: AppTextStyles.withColor(
                        AppTextStyles.bodyLarge,
                        isDark ? Colors.grey[400]! : Colors.grey[600]!,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _items.length,
                (index) => AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 300,
                  ), // Fixed: microseconds to milliseconds
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: currentPage == index
                        ? Theme.of(context).primaryColor
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]
                              : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    handleGetStarted();
                    // Add your skip navigation logic here
                  },
                  child: Text(
                    "Skip",
                    style: AppTextStyles.withColor(
                      AppTextStyles.buttonMedium,
                      isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (currentPage < _items.length - 1) {
                      pageController.nextPage(
                        duration: const Duration(milliseconds: 300), // Added 'const'
                        curve: Curves.easeInOut,
                      );
                    } else {
                      handleGetStarted();
                      // Add your "Get Started" navigation logic here
                      // Example:
                      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    currentPage < _items.length - 1 ? 'Next' : 'Get Started',
                    style: AppTextStyles.withColor(AppTextStyles.buttonMedium, Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String image;
  final String title;
  final String description;

  OnboardingItem({required this.description, required this.title, required this.image});
}
