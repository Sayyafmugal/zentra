// category_controller.dart
import 'package:get/get.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../data/category_seed_data.dart';

export '../models/category.dart';

/// Owns the real, admin-managed category list that replaced the old
/// hardcoded constant in add_product_screen.dart. Public read (any signed-in
/// or anonymous visitor can see the list to filter/browse by), admin-only
/// write — enforced again in firestore.rules, not just here.
class CategoryController extends GetxController {
  CategoryController({CategoryRepository? repository})
    : _repository = repository ?? CategoryRepository();

  static CategoryController get instance => Get.find();

  final CategoryRepository _repository;

  final RxList<Category> categories = <Category>[].obs;
  final RxBool isLoading = false.obs;

  List<String> get categoryNames => categories.map((c) => c.name).toList();

  @override
  void onInit() {
    super.onInit();
    // Public read data — safe to fetch regardless of auth state, and small
    // enough (a few dozen documents at most) that loading it all is fine.
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      categories.value = await _repository.fetchAllCategories();
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  Future<String?> createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Category name can\'t be empty.';

    final id = Category.slugify(trimmed);
    if (id.isEmpty) return 'Please use at least one letter or number.';
    if (categories.any((c) => c.id == id)) return 'That category already exists.';

    try {
      final category = Category(id: id, name: trimmed, createdAt: DateTime.now());
      await _repository.createCategory(category);
      categories.add(category);
      categories.sort((a, b) => a.name.compareTo(b.name));
      return null;
    } catch (e) {
      return 'Failed to create category: $e';
    }
  }

  Future<String?> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      categories.removeWhere((c) => c.id == id);
      return null;
    } catch (e) {
      return 'Failed to delete category: $e';
    }
  }

  /// Explicit, admin-triggered action only (mirrors
  /// ProductController.seedDemoCatalog) — never called implicitly.
  Future<String?> seedDefaultCategories() async {
    try {
      isLoading.value = true;
      await _repository.seedIfMissing(kCategorySeedData);
      await fetchCategories();
      isLoading.value = false;
      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to seed categories: $e';
    }
  }
}
