# CRUD Operations Usage Examples

This document shows how to use the CRUD controllers in your Zentra app.

## Controllers Available

1. **ProductController** - Manage products
2. **CartController** - Manage shopping cart
3. **OrderController** - Manage orders
4. **WishlistController** - Manage wishlist

All controllers are initialized in `main.dart` and can be accessed using `Get.find()`.

---

## 1. ProductController

### Create a Product
```dart
final productController = ProductController.instance;

String? error = await productController.createProduct(
  imagePath: 'assets/images/shoe.jpg',
  name: 'Running Shoes',
  category: 'Footwear',
  currentPrice: 99.99,
  oldPrice: 149.99,
  discount: '33% OFF',
  availableSizes: ['7', '8', '9', '10', '11'],
  description: 'Comfortable running shoes',
);

if (error == null) {
  // Success!
}
```

### Read Products
```dart
final productController = ProductController.instance;

// Fetch all products
await productController.fetchProducts();

// Access products list
List<Product> products = productController.products;

// Get product by ID
Product? product = await productController.getProductById('product123');

// Get products by category
List<Product> footwear = await productController.getProductsByCategory('Footwear');

// Search products
List<Product> results = await productController.searchProducts('shoe');

// Stream products (real-time updates)
Stream<List<Product>> productsStream = productController.getProductsStream();
```

### Update a Product
```dart
final productController = ProductController.instance;

String? error = await productController.updateProduct(
  productId: 'product123',
  name: 'Updated Shoe Name',
  currentPrice: 89.99,
  discount: '40% OFF',
);

if (error == null) {
  // Success!
}
```

### Delete a Product
```dart
final productController = ProductController.instance;

String? error = await productController.deleteProduct('product123');

if (error == null) {
  // Success!
}
```

---

## 2. CartController

### Add to Cart
```dart
final cartController = CartController.instance;

String? error = await cartController.addToCart(
  product: product,
  selectedSize: '9',
  quantity: 1,
);

if (error == null) {
  // Success!
}
```

### Read Cart Items
```dart
final cartController = CartController.instance;

// Fetch cart items
await cartController.fetchCartItems();

// Access cart items
List<CartItem> items = cartController.cartItems;

// Get total price
double total = cartController.totalPrice;

// Get total items count
int itemCount = cartController.totalItems;

// Stream cart items (real-time updates)
Stream<List<CartItem>> cartStream = cartController.getCartItemsStream();
```

### Update Cart Item
```dart
final cartController = CartController.instance;

// Update quantity
String? error = await cartController.updateCartItemQuantity(
  'cartItem123',
  2, // new quantity
);

// Update size
String? error = await cartController.updateCartItemSize(
  'cartItem123',
  '10', // new size
);
```

### Remove from Cart
```dart
final cartController = CartController.instance;

String? error = await cartController.removeFromCart('cartItem123');

// Clear entire cart
String? error = await cartController.clearCart();
```

---

## 3. OrderController

### Create Order
```dart
final orderController = OrderController.instance;

// Create order from cart
String? error = await orderController.createOrderFromCart(
  shippingAddress: '123 Main St, City, State 12345',
  paymentMethod: 'Credit Card',
);

// Or create custom order
List<OrderItem> items = [
  OrderItem(
    productId: 'prod1',
    productName: 'Shoe',
    imagePath: 'assets/images/shoe.jpg',
    price: 99.99,
    quantity: 1,
    selectedSize: '9',
  ),
];

String? error = await orderController.createOrder(
  items: items,
  totalAmount: 99.99,
  shippingAddress: '123 Main St',
  paymentMethod: 'Credit Card',
);
```

### Read Orders
```dart
final orderController = OrderController.instance;

// Fetch orders
await orderController.fetchOrders();

// Access orders list
List<Order> orders = orderController.orders;

// Get order by ID
Order? order = await orderController.getOrderById('order123');

// Stream orders (real-time updates)
Stream<List<Order>> ordersStream = orderController.getOrdersStream();
```

### Update Order Status
```dart
final orderController = OrderController.instance;

// Update status
String? error = await orderController.updateOrderStatus(
  'order123',
  OrderStatus.shipped,
);

// Cancel order
String? error = await orderController.cancelOrder('order123');
```

### Delete Order
```dart
final orderController = OrderController.instance;

String? error = await orderController.deleteOrder('order123');
```

---

## 4. WishlistController

### Add to Wishlist
```dart
final wishlistController = WishlistController.instance;

String? error = await wishlistController.addToWishlist(product);

// Or toggle (add if not exists, remove if exists)
String? error = await wishlistController.toggleWishlist(product);
```

### Read Wishlist
```dart
final wishlistController = WishlistController.instance;

// Fetch wishlist items
await wishlistController.fetchWishlistItems();

// Access wishlist items
List<Product> items = wishlistController.wishlistItems;

// Check if product is in wishlist
bool isFavorite = wishlistController.isInWishlist('product123');

// Stream wishlist items (real-time updates)
Stream<List<Product>> wishlistStream = wishlistController.getWishlistItemsStream();
```

### Remove from Wishlist
```dart
final wishlistController = WishlistController.instance;

String? error = await wishlistController.removeFromWishlist('product123');

// Clear entire wishlist
String? error = await wishlistController.clearWishlist();
```

---

## Using in Widgets with GetX

### Example: Display Products with Reactive Updates
```dart
class ProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productController = ProductController.instance;

    return Obx(() {
      if (productController.isLoading.value) {
        return CircularProgressIndicator();
      }

      return ListView.builder(
        itemCount: productController.products.length,
        itemBuilder: (context, index) {
          final product = productController.products[index];
          return ProductCard(product: product);
        },
      );
    });
  }
}
```

### Example: Cart Screen with Real-time Updates
```dart
class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cartController = CartController.instance;

    return Obx(() {
      return Column(
        children: [
          Text('Total: \$${cartController.totalPrice.toStringAsFixed(2)}'),
          Text('Items: ${cartController.totalItems}'),
          Expanded(
            child: ListView.builder(
              itemCount: cartController.cartItems.length,
              itemBuilder: (context, index) {
                final item = cartController.cartItems[index];
                return CartItemCard(item: item);
              },
            ),
          ),
        ],
      );
    });
  }
}
```

---

## Firestore Collections Structure

The controllers use the following Firestore collections:

- **products** - Stores product data
- **cart** - Stores cart items (user-specific)
- **orders** - Stores order data (user-specific)
- **wishlist** - Stores wishlist items (user-specific)

All user-specific collections filter by `userId` field.

---

## Notes

1. All controllers check if user is logged in before performing operations
2. Error messages are returned as strings (null = success)
3. Success messages are shown via GetX snackbars
4. All controllers use reactive programming with GetX observables
5. Real-time updates are available via stream methods
6. Loading states are managed with `isLoading` observable


