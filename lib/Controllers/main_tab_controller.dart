import 'package:get/get.dart';

/// Shared bottom-nav state for [MainScreen]'s four tabs. Exists so Home can
/// send the user to Shopping — optionally pre-filtered to one category —
/// without needing a direct widget reference to MainScreen's tab index,
/// which is otherwise private State local to that one widget.
class MainTabController extends GetxController {
  static MainTabController get instance => Get.find();

  final RxInt currentIndex = 0.obs;

  /// A category ShoppingTab should select on its next build, then clear.
  /// Empty string means "no pending filter" (Shopping's own "All" sentinel
  /// is reserved for its normal reset, so this uses a separate flag instead
  /// of overloading the same empty-string value both ways).
  final RxString pendingShoppingCategory = ''.obs;

  void setIndex(int index) => currentIndex.value = index;

  /// Switches to the Shopping tab, optionally asking it to pre-select
  /// [category] (from a Home "View All" / category tap).
  void goToShopping({String? category}) {
    if (category != null && category.isNotEmpty) {
      pendingShoppingCategory.value = category;
    }
    currentIndex.value = 1;
  }
}
