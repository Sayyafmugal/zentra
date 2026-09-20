import '../models/category.dart';

/// Default categories — the union of what the old hardcoded picker in
/// add_product_screen.dart offered and what lib/data/product_seed_data.dart
/// actually uses, so seeding this list keeps every existing seeded product's
/// category selectable in the (now real) category picker from day one.
final List<Category> kCategorySeedData =
    ['Shoes', 'Boots', 'Jackets', 'Accessories', 'Electronics', 'Watches', 'Eyewear', 'Other'].map((
      name,
    ) {
      return Category(id: Category.slugify(name), name: name, createdAt: DateTime.now());
    }).toList();
