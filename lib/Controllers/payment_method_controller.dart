// payment_method_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/payment_method.dart';
import '../repositories/payment_method_repository.dart';

export '../models/payment_method.dart';

class PaymentMethodController extends GetxController {
  PaymentMethodController({PaymentMethodRepository? repository})
    : _repository = repository ?? PaymentMethodRepository();

  static PaymentMethodController get instance => Get.find();

  final PaymentMethodRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<PaymentMethod> paymentMethods = <PaymentMethod>[].obs;
  final RxBool isLoading = false.obs;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    if (currentUserId != null) {
      fetchPaymentMethods();
    }
  }

  // ==================== CREATE ====================
  Future<String?> addPaymentMethod({
    required PaymentType type,
    required String cardNumber,
    required String expiryDate,
    String? cardholderName,
    bool setAsDefault = false,
  }) async {
    try {
      if (currentUserId == null) {
        return 'Please login to add payment methods';
      }

      isLoading.value = true;

      final last4Digits = cardNumber.length >= 4
          ? cardNumber.substring(cardNumber.length - 4)
          : cardNumber;

      if (setAsDefault) {
        await _unsetAllDefaults();
      }

      final newPayment = PaymentMethod(
        id: _repository.newPaymentMethodId(),
        userId: currentUserId!,
        type: type,
        cardNumber: last4Digits,
        expiryDate: expiryDate.trim(),
        cardholderName: cardholderName?.trim(),
        isDefault: setAsDefault,
        createdAt: DateTime.now(),
      );

      await _repository.addPaymentMethod(newPayment);

      paymentMethods.add(newPayment);
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to add payment method: $e';
    }
  }

  // ==================== READ ====================
  Future<void> fetchPaymentMethods() async {
    try {
      if (currentUserId == null) return;

      isLoading.value = true;
      paymentMethods.value = await _repository.fetchPaymentMethods(currentUserId!);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  Stream<List<PaymentMethod>> getPaymentMethodsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _repository.watchPaymentMethods(currentUserId!);
  }

  PaymentMethod? get defaultPaymentMethod =>
      paymentMethods.firstWhereOrNull((method) => method.isDefault);

  PaymentMethod? getPaymentMethodById(String paymentId) =>
      paymentMethods.firstWhereOrNull((method) => method.id == paymentId);

  // ==================== UPDATE ====================
  Future<String?> updatePaymentMethod({
    required String paymentId,
    PaymentType? type,
    String? expiryDate,
    String? cardholderName,
    bool? setAsDefault,
  }) async {
    try {
      isLoading.value = true;

      final updateData = <String, dynamic>{};
      if (type != null) updateData['type'] = type.name;
      if (expiryDate != null) updateData['expiryDate'] = expiryDate.trim();
      if (cardholderName != null) updateData['cardholderName'] = cardholderName.trim();

      if (setAsDefault == true) {
        await _unsetAllDefaults();
        updateData['isDefault'] = true;
      } else if (setAsDefault == false) {
        updateData['isDefault'] = false;
      }

      await _repository.updatePaymentMethod(paymentId, updateData);

      final index = paymentMethods.indexWhere((method) => method.id == paymentId);
      if (index != -1) {
        paymentMethods[index] = paymentMethods[index].copyWith(
          type: type,
          expiryDate: expiryDate,
          cardholderName: cardholderName,
          isDefault: setAsDefault,
          updatedAt: DateTime.now(),
        );
      }

      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update payment method: $e';
    }
  }

  Future<String?> setAsDefault(String paymentId) async {
    return await updatePaymentMethod(paymentId: paymentId, setAsDefault: true);
  }

  Future<void> _unsetAllDefaults() async {
    final defaultIds = paymentMethods
        .where((method) => method.isDefault)
        .map((method) => method.id)
        .toList();
    await _repository.unsetDefaults(defaultIds);
  }

  // ==================== DELETE ====================
  Future<String?> deletePaymentMethod(String paymentId) async {
    try {
      isLoading.value = true;
      await _repository.deletePaymentMethod(paymentId);

      paymentMethods.removeWhere((method) => method.id == paymentId);
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to delete payment method: $e';
    }
  }
}
