// payment_method_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

enum PaymentType {
  visa,
  mastercard,
  amex,
  discover,
  paypal,
  other,
}

class PaymentMethod {
  final String id;
  final String userId;
  final PaymentType type;
  final String cardNumber; // Last 4 digits only for security
  final String expiryDate; // MM/YY format
  final String? cardholderName;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.cardNumber,
    required this.expiryDate,
    this.cardholderName,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cardholderName': cardholderName,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: PaymentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PaymentType.other,
      ),
      cardNumber: map['cardNumber'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      cardholderName: map['cardholderName'],
      isDefault: map['isDefault'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethod.fromMap(data);
  }

  String get maskedCardNumber {
    if (cardNumber.length <= 4) return '**** **** **** $cardNumber';
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  String get displayName {
    switch (type) {
      case PaymentType.visa:
        return 'Visa';
      case PaymentType.mastercard:
        return 'Mastercard';
      case PaymentType.amex:
        return 'American Express';
      case PaymentType.discover:
        return 'Discover';
      case PaymentType.paypal:
        return 'PayPal';
      case PaymentType.other:
        return 'Other';
    }
  }
}

class PaymentMethodController extends GetxController {
  static PaymentMethodController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    required String cardNumber, // Full card number (will be masked)
    required String expiryDate,
    String? cardholderName,
    bool setAsDefault = false,
  }) async {
    try {
      if (currentUserId == null) {
        return 'Please login to add payment methods';
      }

      isLoading.value = true;

      // Extract last 4 digits for storage (security best practice)
      final last4Digits = cardNumber.length >= 4
          ? cardNumber.substring(cardNumber.length - 4)
          : cardNumber;

      // If setting as default, unset other defaults
      if (setAsDefault) {
        await _unsetAllDefaults();
      }

      final paymentId = _firestore.collection('paymentMethods').doc().id;
      final newPayment = PaymentMethod(
        id: paymentId,
        userId: currentUserId!,
        type: type,
        cardNumber: last4Digits,
        expiryDate: expiryDate.trim(),
        cardholderName: cardholderName?.trim(),
        isDefault: setAsDefault,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('paymentMethods').doc(paymentId).set(newPayment.toMap());

      paymentMethods.add(newPayment);
      isLoading.value = false;

      Get.snackbar(
        'Success!',
        'Payment method added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

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

      final snapshot = await _firestore
          .collection('paymentMethods')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      paymentMethods.value = snapshot.docs
          .map((doc) => PaymentMethod.fromFirestore(doc))
          .toList();

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to fetch payment methods: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Stream payment methods for real-time updates
  Stream<List<PaymentMethod>> getPaymentMethodsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('paymentMethods')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentMethod.fromFirestore(doc))
            .toList());
  }

  // Get default payment method
  PaymentMethod? get defaultPaymentMethod {
    try {
      return paymentMethods.firstWhereOrNull((method) => method.isDefault);
    } catch (e) {
      return null;
    }
  }

  // Get payment method by ID
  PaymentMethod? getPaymentMethodById(String paymentId) {
    try {
      return paymentMethods.firstWhereOrNull((method) => method.id == paymentId);
    } catch (e) {
      return null;
    }
  }

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

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (type != null) updateData['type'] = type.name;
      if (expiryDate != null) updateData['expiryDate'] = expiryDate.trim();
      if (cardholderName != null) updateData['cardholderName'] = cardholderName.trim();

      if (setAsDefault == true) {
        await _unsetAllDefaults();
        updateData['isDefault'] = true;
      } else if (setAsDefault == false) {
        updateData['isDefault'] = false;
      }

      await _firestore.collection('paymentMethods').doc(paymentId).update(updateData);

      // Update local list
      final index = paymentMethods.indexWhere((method) => method.id == paymentId);
      if (index != -1) {
        final current = paymentMethods[index];
        paymentMethods[index] = PaymentMethod(
          id: current.id,
          userId: current.userId,
          type: type ?? current.type,
          cardNumber: current.cardNumber,
          expiryDate: expiryDate ?? current.expiryDate,
          cardholderName: cardholderName ?? current.cardholderName,
          isDefault: setAsDefault ?? current.isDefault,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
        );
        paymentMethods.refresh();
      }

      isLoading.value = false;

      Get.snackbar(
        'Success!',
        'Payment method updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update payment method: $e';
    }
  }

  // Set payment method as default
  Future<String?> setAsDefault(String paymentId) async {
    return await updatePaymentMethod(paymentId: paymentId, setAsDefault: true);
  }

  // Helper to unset all defaults
  Future<void> _unsetAllDefaults() async {
    final defaultMethods = paymentMethods.where((method) => method.isDefault).toList();
    final batch = _firestore.batch();

    for (var method in defaultMethods) {
      batch.update(
        _firestore.collection('paymentMethods').doc(method.id),
        {'isDefault': false},
      );
    }

    if (defaultMethods.isNotEmpty) {
      await batch.commit();
    }
  }

  // ==================== DELETE ====================
  Future<String?> deletePaymentMethod(String paymentId) async {
    try {
      isLoading.value = true;

      await _firestore.collection('paymentMethods').doc(paymentId).delete();

      paymentMethods.removeWhere((method) => method.id == paymentId);
      isLoading.value = false;

      Get.snackbar(
        'Deleted',
        'Payment method deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to delete payment method: $e';
    }
  }
}

