// address_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class Address {
  final String id;
  final String userId;
  final String name; // e.g., "Home", "Office"
  final String fullName;
  final String address;
  final String city;
  final String? state;
  final String? zipCode;
  final String country;
  final String phone;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Address({
    required this.id,
    required this.userId,
    required this.name,
    required this.fullName,
    required this.address,
    required this.city,
    this.state,
    this.zipCode,
    required this.country,
    required this.phone,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'fullName': fullName,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'phone': phone,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      fullName: map['fullName'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'],
      zipCode: map['zipCode'],
      country: map['country'] ?? 'USA',
      phone: map['phone'] ?? '',
      isDefault: map['isDefault'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  factory Address.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Address.fromMap(data);
  }

  String get fullAddress {
    final parts = [address, city];
    if (state != null) parts.add(state!);
    if (zipCode != null) parts.add(zipCode!);
    parts.add(country);
    return parts.join(', ');
  }
}

class AddressController extends GetxController {
  static AddressController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<Address> addresses = <Address>[].obs;
  final RxBool isLoading = false.obs;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    if (currentUserId != null) {
      fetchAddresses();
    }
  }

  // ==================== CREATE ====================
  Future<String?> addAddress({
    required String name,
    required String fullName,
    required String address,
    required String city,
    String? state,
    String? zipCode,
    String country = 'USA',
    required String phone,
    bool setAsDefault = false,
  }) async {
    try {
      if (currentUserId == null) {
        return 'Please login to add addresses';
      }

      isLoading.value = true;

      // If setting as default, unset other defaults
      if (setAsDefault) {
        await _unsetAllDefaults();
      }

      final addressId = _firestore.collection('addresses').doc().id;
      final newAddress = Address(
        id: addressId,
        userId: currentUserId!,
        name: name.trim(),
        fullName: fullName.trim(),
        address: address.trim(),
        city: city.trim(),
        state: state?.trim(),
        zipCode: zipCode?.trim(),
        country: country.trim(),
        phone: phone.trim(),
        isDefault: setAsDefault,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('addresses').doc(addressId).set(newAddress.toMap());

      addresses.add(newAddress);
      isLoading.value = false;

      Get.snackbar(
        'Success!',
        'Address added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to add address: $e';
    }
  }

  // ==================== READ ====================
  Future<void> fetchAddresses() async {
    try {
      if (currentUserId == null) return;

      isLoading.value = true;

      final snapshot = await _firestore
          .collection('addresses')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      addresses.value = snapshot.docs
          .map((doc) => Address.fromFirestore(doc))
          .toList();

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to fetch addresses: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Stream addresses for real-time updates
  Stream<List<Address>> getAddressesStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('addresses')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Address.fromFirestore(doc))
            .toList());
  }

  // Get default address
  Address? get defaultAddress {
    try {
      return addresses.firstWhereOrNull((addr) => addr.isDefault);
    } catch (e) {
      return null;
    }
  }

  // Get address by ID
  Address? getAddressById(String addressId) {
    try {
      return addresses.firstWhereOrNull((addr) => addr.id == addressId);
    } catch (e) {
      return null;
    }
  }

  // ==================== UPDATE ====================
  Future<String?> updateAddress({
    required String addressId,
    String? name,
    String? fullName,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? phone,
    bool? setAsDefault,
  }) async {
    try {
      isLoading.value = true;

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name.trim();
      if (fullName != null) updateData['fullName'] = fullName.trim();
      if (address != null) updateData['address'] = address.trim();
      if (city != null) updateData['city'] = city.trim();
      if (state != null) updateData['state'] = state.trim();
      if (zipCode != null) updateData['zipCode'] = zipCode.trim();
      if (country != null) updateData['country'] = country.trim();
      if (phone != null) updateData['phone'] = phone.trim();

      if (setAsDefault == true) {
        await _unsetAllDefaults();
        updateData['isDefault'] = true;
      } else if (setAsDefault == false) {
        updateData['isDefault'] = false;
      }

      await _firestore.collection('addresses').doc(addressId).update(updateData);

      // Update local list
      final index = addresses.indexWhere((addr) => addr.id == addressId);
      if (index != -1) {
        final current = addresses[index];
        addresses[index] = Address(
          id: current.id,
          userId: current.userId,
          name: name ?? current.name,
          fullName: fullName ?? current.fullName,
          address: address ?? current.address,
          city: city ?? current.city,
          state: state ?? current.state,
          zipCode: zipCode ?? current.zipCode,
          country: country ?? current.country,
          phone: phone ?? current.phone,
          isDefault: setAsDefault ?? current.isDefault,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
        );
        addresses.refresh();
      }

      isLoading.value = false;

      Get.snackbar(
        'Success!',
        'Address updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update address: $e';
    }
  }

  // Set address as default
  Future<String?> setAsDefault(String addressId) async {
    return await updateAddress(addressId: addressId, setAsDefault: true);
  }

  // Helper to unset all defaults
  Future<void> _unsetAllDefaults() async {
    final defaultAddresses = addresses.where((addr) => addr.isDefault).toList();
    final batch = _firestore.batch();

    for (var addr in defaultAddresses) {
      batch.update(
        _firestore.collection('addresses').doc(addr.id),
        {'isDefault': false},
      );
    }

    if (defaultAddresses.isNotEmpty) {
      await batch.commit();
    }
  }

  // ==================== DELETE ====================
  Future<String?> deleteAddress(String addressId) async {
    try {
      isLoading.value = true;

      await _firestore.collection('addresses').doc(addressId).delete();

      addresses.removeWhere((addr) => addr.id == addressId);
      isLoading.value = false;

      Get.snackbar(
        'Deleted',
        'Address deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to delete address: $e';
    }
  }
}

