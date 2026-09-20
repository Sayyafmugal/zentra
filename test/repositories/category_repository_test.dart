import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/category.dart';
import 'package:zentra_0/repositories/category_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CategoryRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = CategoryRepository(firestore: firestore);
  });

  Category buildCategory(String name) {
    return Category(id: Category.slugify(name), name: name, createdAt: DateTime(2026, 1, 1));
  }

  test('createCategory writes the category at its slug as the doc id', () async {
    await repository.createCategory(buildCategory('Shoes'));

    final doc = await firestore.collection('categories').doc('shoes').get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['name'], 'Shoes');
  });

  test('fetchAllCategories returns every category alphabetically by name', () async {
    await repository.createCategory(buildCategory('Watches'));
    await repository.createCategory(buildCategory('Boots'));

    final all = await repository.fetchAllCategories();

    expect(all.map((c) => c.name), ['Boots', 'Watches']);
  });

  test('deleteCategory removes the document', () async {
    await repository.createCategory(buildCategory('Shoes'));

    await repository.deleteCategory('shoes');

    final doc = await firestore.collection('categories').doc('shoes').get();
    expect(doc.exists, isFalse);
  });

  group('seedIfMissing', () {
    test('writes every category that does not already exist', () async {
      await repository.seedIfMissing([buildCategory('Shoes'), buildCategory('Boots')]);

      final all = await repository.fetchAllCategories();
      expect(all.map((c) => c.name), containsAll(['Shoes', 'Boots']));
    });

    test('never overwrites a category that already exists', () async {
      await repository.createCategory(buildCategory('Shoes'));
      await firestore.collection('categories').doc('shoes').update({'name': 'Renamed by admin'});

      await repository.seedIfMissing([buildCategory('Shoes')]);

      final doc = await firestore.collection('categories').doc('shoes').get();
      expect(doc.data()!['name'], 'Renamed by admin');
    });
  });
}
