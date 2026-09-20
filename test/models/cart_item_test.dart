import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/cart_item.dart';
import 'package:zentra_0/models/product.dart';

void main() {
  const product = Product(
    id: 'p1',
    imagePath: 'assets/images/shoe.jpg',
    name: 'Air Runner',
    category: 'Shoes',
    currentPrice: 25.0,
    availableSizes: ['M'],
    description: 'desc',
  );

  group('CartItem', () {
    test('totalPrice multiplies unit price by quantity', () {
      const item = CartItem(
        id: 'c1',
        product: product,
        quantity: 3,
        selectedSize: 'M',
        userId: 'u1',
      );
      expect(item.totalPrice, 75.0);
    });

    test('round-trips through toMap/fromMap', () {
      const item = CartItem(
        id: 'c1',
        product: product,
        quantity: 2,
        selectedSize: 'M',
        userId: 'u1',
      );
      final restored = CartItem.fromMap(item.toMap(), product);
      expect(restored, equals(item));
    });

    test('copyWith updates quantity without touching other fields', () {
      const item = CartItem(
        id: 'c1',
        product: product,
        quantity: 1,
        selectedSize: 'M',
        userId: 'u1',
      );
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.selectedSize, 'M');
      expect(updated.product, product);
    });
  });
}
