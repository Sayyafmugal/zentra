// address_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/address.dart';
import '../repositories/address_repository.dart';

export '../models/address.dart';

class AddressController extends GetxController {
  AddressController({AddressRepository? repository})
    : _repository = repository ?? AddressRepository();

  static AddressController get instance => Get.find();

  final AddressRepository _repository;
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

      if (setAsDefault) {
        await _unsetAllDefaults();
      }

      final newAddress = Address(
        id: _repository.newAddressId(),
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

      await _repository.addAddress(newAddress);

      addresses.add(newAddress);
      isLoading.value = false;

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
      addresses.value = await _repository.fetchAddresses(currentUserId!);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  Stream<List<Address>> getAddressesStream() {
    if (currentUserId == null) return Stream.value([]);
    return _repository.watchAddresses(currentUserId!);
  }

  Address? get defaultAddress => addresses.firstWhereOrNull((addr) => addr.isDefault);

  Address? getAddressById(String addressId) =>
      addresses.firstWhereOrNull((addr) => addr.id == addressId);

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

      final updateData = <String, dynamic>{};
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

      await _repository.updateAddress(addressId, updateData);

      final index = addresses.indexWhere((addr) => addr.id == addressId);
      if (index != -1) {
        addresses[index] = addresses[index].copyWith(
          name: name,
          fullName: fullName,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          country: country,
          phone: phone,
          isDefault: setAsDefault,
          updatedAt: DateTime.now(),
        );
      }

      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update address: $e';
    }
  }

  Future<String?> setAsDefault(String addressId) async {
    return await updateAddress(addressId: addressId, setAsDefault: true);
  }

  Future<void> _unsetAllDefaults() async {
    final defaultIds = addresses.where((addr) => addr.isDefault).map((addr) => addr.id).toList();
    await _repository.unsetDefaults(defaultIds);
  }

  // ==================== DELETE ====================
  Future<String?> deleteAddress(String addressId) async {
    try {
      isLoading.value = true;
      await _repository.deleteAddress(addressId);

      addresses.removeWhere((addr) => addr.id == addressId);
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to delete address: $e';
    }
  }
}
