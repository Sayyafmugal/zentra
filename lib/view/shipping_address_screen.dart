import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/address_controller.dart';

class ShippingAddressScreen extends StatelessWidget {
  const ShippingAddressScreen({super.key});

  static const Color primaryColor = Color(0xFFFF5200);

  @override
  Widget build(BuildContext context) {
    final addressController = AddressController.instance;

    // Fetch addresses on first load
    if (addressController.addresses.isEmpty && !addressController.isLoading.value) {
      addressController.fetchAddresses();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Shipping Addresses",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Obx(() {
        if (addressController.isLoading.value && addressController.addresses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (addressController.addresses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No addresses yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add Your First Address",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => _showAddAddressDialog(context, addressController),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: addressController.addresses.length,
                  itemBuilder: (context, index) {
                    final address = addressController.addresses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: address.isDefault
                            ? BorderSide(color: primaryColor, width: 2)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.location_on,
                          color: address.isDefault ? primaryColor : Colors.red,
                        ),
                        title: Row(
                          children: [
                            Text(
                              address.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (address.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'DEFAULT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(address.fullName),
                            Text(address.fullAddress),
                            Text(address.phone, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditAddressDialog(context, addressController, address);
                            } else if (value == 'delete') {
                              _showDeleteConfirmDialog(context, addressController, address.id);
                            } else if (value == 'default' && !address.isDefault) {
                              addressController.setAsDefault(address.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text("Edit")),
                            if (!address.isDefault)
                              const PopupMenuItem(value: 'default', child: Text("Set as Default")),
                            const PopupMenuItem(value: 'delete', child: Text("Delete")),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add New Address",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showAddAddressDialog(context, addressController),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showAddAddressDialog(BuildContext context, AddressController controller) {
    final nameCtrl = TextEditingController();
    final fullNameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final zipCodeCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool setAsDefault = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add New Address"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Label (e.g. Home, Office)"),
                    ),
                    TextField(
                      controller: fullNameCtrl,
                      decoration: const InputDecoration(labelText: "Full Name"),
                    ),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: "Street Address"),
                    ),
                    TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(labelText: "City"),
                    ),
                    TextField(
                      controller: stateCtrl,
                      decoration: const InputDecoration(labelText: "State (Optional)"),
                    ),
                    TextField(
                      controller: zipCodeCtrl,
                      decoration: const InputDecoration(labelText: "ZIP Code (Optional)"),
                    ),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: "Phone Number"),
                      keyboardType: TextInputType.phone,
                    ),
                    CheckboxListTile(
                      title: const Text("Set as default address"),
                      value: setAsDefault,
                      onChanged: (val) => setState(() => setAsDefault = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    nameCtrl.dispose();
                    fullNameCtrl.dispose();
                    addressCtrl.dispose();
                    cityCtrl.dispose();
                    stateCtrl.dispose();
                    zipCodeCtrl.dispose();
                    phoneCtrl.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  onPressed: () async {
                    if (nameCtrl.text.isNotEmpty &&
                        fullNameCtrl.text.isNotEmpty &&
                        addressCtrl.text.isNotEmpty &&
                        cityCtrl.text.isNotEmpty &&
                        phoneCtrl.text.isNotEmpty) {
                      final error = await controller.addAddress(
                        name: nameCtrl.text,
                        fullName: fullNameCtrl.text,
                        address: addressCtrl.text,
                        city: cityCtrl.text,
                        state: stateCtrl.text.isEmpty ? null : stateCtrl.text,
                        zipCode: zipCodeCtrl.text.isEmpty ? null : zipCodeCtrl.text,
                        phone: phoneCtrl.text,
                        setAsDefault: setAsDefault,
                      );

                      nameCtrl.dispose();
                      fullNameCtrl.dispose();
                      addressCtrl.dispose();
                      cityCtrl.dispose();
                      stateCtrl.dispose();
                      zipCodeCtrl.dispose();
                      phoneCtrl.dispose();

                      if (error == null) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text("Add", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditAddressDialog(
      BuildContext context, AddressController controller, Address address) {
    final nameCtrl = TextEditingController(text: address.name);
    final fullNameCtrl = TextEditingController(text: address.fullName);
    final addressCtrl = TextEditingController(text: address.address);
    final cityCtrl = TextEditingController(text: address.city);
    final stateCtrl = TextEditingController(text: address.state ?? '');
    final zipCodeCtrl = TextEditingController(text: address.zipCode ?? '');
    final phoneCtrl = TextEditingController(text: address.phone);
    bool setAsDefault = address.isDefault;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Address"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Label"),
                    ),
                    TextField(
                      controller: fullNameCtrl,
                      decoration: const InputDecoration(labelText: "Full Name"),
                    ),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: "Street Address"),
                    ),
                    TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(labelText: "City"),
                    ),
                    TextField(
                      controller: stateCtrl,
                      decoration: const InputDecoration(labelText: "State (Optional)"),
                    ),
                    TextField(
                      controller: zipCodeCtrl,
                      decoration: const InputDecoration(labelText: "ZIP Code (Optional)"),
                    ),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: "Phone Number"),
                      keyboardType: TextInputType.phone,
                    ),
                    CheckboxListTile(
                      title: const Text("Set as default address"),
                      value: setAsDefault,
                      onChanged: (val) => setState(() => setAsDefault = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    nameCtrl.dispose();
                    fullNameCtrl.dispose();
                    addressCtrl.dispose();
                    cityCtrl.dispose();
                    stateCtrl.dispose();
                    zipCodeCtrl.dispose();
                    phoneCtrl.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  onPressed: () async {
                    final error = await controller.updateAddress(
                      addressId: address.id,
                      name: nameCtrl.text,
                      fullName: fullNameCtrl.text,
                      address: addressCtrl.text,
                      city: cityCtrl.text,
                      state: stateCtrl.text.isEmpty ? null : stateCtrl.text,
                      zipCode: zipCodeCtrl.text.isEmpty ? null : zipCodeCtrl.text,
                      phone: phoneCtrl.text,
                      setAsDefault: setAsDefault != address.isDefault ? setAsDefault : null,
                    );

                    nameCtrl.dispose();
                    fullNameCtrl.dispose();
                    addressCtrl.dispose();
                    cityCtrl.dispose();
                    stateCtrl.dispose();
                    zipCodeCtrl.dispose();
                    phoneCtrl.dispose();

                    if (error == null) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, AddressController controller, String addressId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Address"),
        content: const Text("Are you sure you want to delete this address?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await controller.deleteAddress(addressId);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
