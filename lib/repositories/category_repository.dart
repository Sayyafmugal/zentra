import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

/// Wraps all Firestore access for the `categories` collection. Small and
/// admin-managed by nature — unlike products/orders, this is never expected
/// to grow past a few dozen documents, so a plain full-collection fetch (no
/// pagination) is the right fit rather than premature complexity.
class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('categories');

  Future<void> createCategory(Category category) async {
    await _collection.doc(category.id).set(category.toMap());
  }

  Future<List<Category>> fetchAllCategories() async {
    final snapshot = await _collection.orderBy('name').get();
    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  Future<void> deleteCategory(String id) async {
    await _collection.doc(id).delete();
  }

  /// Writes every category in [categories] that doesn't already exist —
  /// used for the one-time "seed default categories" admin action, not
  /// called implicitly (same convention as ProductRepository.seedProducts).
  Future<void> seedIfMissing(List<Category> categories) async {
    final existingIds = (await _collection.get()).docs.map((d) => d.id).toSet();
    final batch = _firestore.batch();
    var pending = 0;
    for (final category in categories) {
      if (!existingIds.contains(category.id)) {
        batch.set(_collection.doc(category.id), category.toMap());
        pending++;
      }
    }
    if (pending > 0) await batch.commit();
  }
}
