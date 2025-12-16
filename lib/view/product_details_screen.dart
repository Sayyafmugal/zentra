import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'product_model.dart'; // Import Product model
import '../Controllers/cart_controller.dart';
import '../Controllers/wishlist_controller.dart';
import 'my_cart_screen.dart'; // Your Cart Screen
import 'checkout_screen.dart'; // Your Checkout Screen

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  static const Color primaryColor = Color(0xFFFF5200);
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    // Set default size
    if (widget.product.availableSizes.isNotEmpty) {
      _selectedSize = widget.product.availableSizes[0];
    }
  }

  String _formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {
              print('Share pressed for ${widget.product.name}');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- Product Image Section ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              color: Colors.grey[200],
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    widget.product.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                      child: Obx(() {
                        final wishlistController = WishlistController.instance;
                        final isInWishlist = wishlistController.isInWishlist(widget.product.id);
                        
                        return IconButton(
                          icon: Icon(
                            isInWishlist ? Icons.favorite : Icons.favorite_border,
                            color: isInWishlist ? Colors.red : Colors.black,
                            size: 28,
                          ),
                          onPressed: () {
                            wishlistController.toggleWishlist(widget.product);
                          },
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Product Details Panel ---
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name & Price
                    Text(
                      widget.product.name,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Category: ${widget.product.category}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          _formatPrice(widget.product.currentPrice),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- Size Selector ---
                    const Text(
                      'Select Size',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: widget.product.availableSizes.map((size) {
                        bool isSelected = _selectedSize == size;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedSize = size);
                          },
                          child: Container(
                            width: 45,
                            height: 45,
                            margin: const EdgeInsets.only(right: 15),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? primaryColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              size,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),

                    // --- Description Section ---
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.product.description,
                      style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Shipping & Returns',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Free shipping on orders over \$100. Easy 30-day returns accepted.',
                      style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Bottom Buttons ---
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Add to Cart Button
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (_selectedSize != null) {
                            final cartController = CartController.instance;
                            final error = await cartController.addToCart(
                              product: widget.product,
                              selectedSize: _selectedSize!,
                              quantity: 1,
                            );

                            if (error == null) {
                              // Show success message and optionally navigate to cart
                              Get.snackbar(
                                'Added to Cart',
                                '${widget.product.name} added to cart',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                                duration: const Duration(seconds: 2),
                              );
                              
                              // Optionally navigate to cart after a short delay
                              // Uncomment the lines below if you want to auto-navigate
                              // Future.delayed(const Duration(milliseconds: 500), () {
                              //   Navigator.push(
                              //     context,
                              //     MaterialPageRoute(builder: (context) => const MyCartScreen()),
                              //   );
                              // });
                            } else {
                              Get.snackbar(
                                'Error',
                                error,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          } else {
                            Get.snackbar(
                              'Select Size',
                              'Please select a size first',
                              backgroundColor: Colors.orange,
                              colorText: Colors.white,
                            );
                          }
                        },
                        icon: const Icon(Icons.shopping_bag_outlined, color: primaryColor),
                        label: const Text(
                          'Add To Cart',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryColor, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Buy Now Button
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_selectedSize != null) {
                            print('Buy Now: ${widget.product.name} (Size: $_selectedSize)');

                            // ✅ Navigate to Checkout screen with product info
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(
                                  totalAmount: widget.product.currentPrice,
                                  itemCount: 1,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a size first')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Buy Now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
