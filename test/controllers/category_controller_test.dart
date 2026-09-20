import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zentra_0/Controllers/category_controller.dart';
import 'package:zentra_0/repositories/category_repository.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Category(id: 'x', name: 'x', createdAt: DateTime(2026, 1, 1)));
  });

  late MockCategoryRepository repository;
  late CategoryController controller;

  setUp(() {
    repository = MockCategoryRepository();
    when(() => repository.fetchAllCategories()).thenAnswer((_) async => []);
    controller = CategoryController(repository: repository);
  });

  group('CategoryController.createCategory', () {
    test('rejects an empty name without touching the repository', () async {
      final error = await controller.createCategory('   ');

      expect(error, isNotNull);
      verifyNever(() => repository.createCategory(any()));
    });

    test('slugifies the name into the id and adds it to the local list', () async {
      when(() => repository.createCategory(any())).thenAnswer((_) async {});

      final error = await controller.createCategory('Sports Wear');

      expect(error, isNull);
      expect(controller.categories, hasLength(1));
      expect(controller.categories.first.id, 'sports-wear');
      expect(controller.categories.first.name, 'Sports Wear');
    });

    test('rejects a duplicate category (case/spacing-insensitive via the slug)', () async {
      when(() => repository.createCategory(any())).thenAnswer((_) async {});
      await controller.createCategory('Shoes');

      final error = await controller.createCategory('shoes');

      expect(error, isNotNull);
      verify(() => repository.createCategory(any())).called(1);
    });
  });

  group('CategoryController.deleteCategory', () {
    test('removes the category from the local list on success', () async {
      when(() => repository.createCategory(any())).thenAnswer((_) async {});
      when(() => repository.deleteCategory('shoes')).thenAnswer((_) async {});
      await controller.createCategory('Shoes');

      final error = await controller.deleteCategory('shoes');

      expect(error, isNull);
      expect(controller.categories, isEmpty);
    });
  });

  group('CategoryController.seedDefaultCategories', () {
    test('delegates to the repository and refreshes the local list', () async {
      when(() => repository.seedIfMissing(any())).thenAnswer((_) async {});
      when(() => repository.fetchAllCategories()).thenAnswer(
        (_) async => [Category(id: 'shoes', name: 'Shoes', createdAt: DateTime(2026, 1, 1))],
      );

      final error = await controller.seedDefaultCategories();

      expect(error, isNull);
      expect(controller.categories, hasLength(1));
    });
  });
}
