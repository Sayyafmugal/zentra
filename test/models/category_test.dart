import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/category.dart';

void main() {
  group('Category.slugify', () {
    test('lowercases and hyphenates spaces', () {
      expect(Category.slugify('Sports Wear'), 'sports-wear');
    });

    test('trims surrounding whitespace', () {
      expect(Category.slugify('  Shoes  '), 'shoes');
    });

    test('strips punctuation that would otherwise break a document id', () {
      expect(Category.slugify('Men\'s / Women\'s'), 'mens-womens');
    });
  });

  group('Category toMap/fromMap round-trip', () {
    test('preserves every field', () {
      final category = Category(id: 'shoes', name: 'Shoes', createdAt: DateTime(2026, 1, 1));

      final roundTripped = Category.fromMap(category.toMap());

      expect(roundTripped, category);
    });
  });
}
