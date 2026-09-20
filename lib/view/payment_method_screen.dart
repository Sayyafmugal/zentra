import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/payment_method_controller.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final paymentController = PaymentMethodController.instance;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Fetch payment methods on first load
    if (paymentController.paymentMethods.isEmpty && !paymentController.isLoading.value) {
      paymentController.fetchPaymentMethods();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Payment Methods")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demo only — no real payment provider is configured. Cards saved here '
                    'never process a real charge; use Cash on Delivery for a real order.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(context, paymentController, primaryColor)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PaymentMethodController paymentController,
    Color primaryColor,
  ) {
    return Obx(() {
      if (paymentController.isLoading.value && paymentController.paymentMethods.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (paymentController.paymentMethods.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.credit_card_outlined, size: 80, color: Theme.of(context).hintColor),
              const SizedBox(height: 16),
              Text('No payment methods yet', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Your First Payment Method"),
                onPressed: () => _showAddPaymentDialog(context, paymentController),
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
                itemCount: paymentController.paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = paymentController.paymentMethods[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: method.isDefault
                          ? BorderSide(color: primaryColor, width: 2)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.credit_card, color: Colors.blue),
                      title: Row(
                        children: [
                          Text(
                            "${method.displayName} (${method.maskedCardNumber})",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (method.isDefault) ...[
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
                      subtitle: Text("Expires ${method.expiryDate}"),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditPaymentDialog(context, paymentController, method);
                          } else if (value == 'delete') {
                            _showDeleteConfirmDialog(context, paymentController, method.id);
                          } else if (value == 'default' && !method.isDefault) {
                            paymentController.setAsDefault(method.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text("Edit")),
                          if (!method.isDefault)
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
                  "Add New Payment Method",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showAddPaymentDialog(context, paymentController),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showAddPaymentDialog(BuildContext context, PaymentMethodController controller) {
    PaymentType selectedType = PaymentType.visa;
    final cardNumberCtrl = TextEditingController();
    final expiryDateCtrl = TextEditingController();
    final cardholderNameCtrl = TextEditingController();
    bool setAsDefault = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add Payment Method"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<PaymentType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: "Card Type"),
                      items: PaymentType.values.map((type) {
                        String label;
                        switch (type) {
                          case PaymentType.visa:
                            label = 'Visa';
                            break;
                          case PaymentType.mastercard:
                            label = 'Mastercard';
                            break;
                          case PaymentType.amex:
                            label = 'American Express';
                            break;
                          case PaymentType.discover:
                            label = 'Discover';
                            break;
                          case PaymentType.paypal:
                            label = 'PayPal';
                            break;
                          case PaymentType.other:
                            label = 'Other';
                            break;
                        }
                        return DropdownMenuItem(value: type, child: Text(label));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedType = value);
                        }
                      },
                    ),
                    TextField(
                      controller: cardNumberCtrl,
                      decoration: const InputDecoration(labelText: "Card Number"),
                      keyboardType: TextInputType.number,
                      maxLength: 19,
                    ),
                    TextField(
                      controller: expiryDateCtrl,
                      decoration: const InputDecoration(labelText: "Expiry Date (MM/YY)"),
                      maxLength: 5,
                    ),
                    TextField(
                      controller: cardholderNameCtrl,
                      decoration: const InputDecoration(labelText: "Cardholder Name (Optional)"),
                    ),
                    CheckboxListTile(
                      title: const Text("Set as default payment method"),
                      value: setAsDefault,
                      onChanged: (val) => setState(() => setAsDefault = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    cardNumberCtrl.dispose();
                    expiryDateCtrl.dispose();
                    cardholderNameCtrl.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () async {
                    if (cardNumberCtrl.text.isNotEmpty && expiryDateCtrl.text.isNotEmpty) {
                      final error = await controller.addPaymentMethod(
                        type: selectedType,
                        cardNumber: cardNumberCtrl.text.replaceAll(' ', ''),
                        expiryDate: expiryDateCtrl.text,
                        cardholderName: cardholderNameCtrl.text.isEmpty
                            ? null
                            : cardholderNameCtrl.text,
                        setAsDefault: setAsDefault,
                      );

                      cardNumberCtrl.dispose();
                      expiryDateCtrl.dispose();
                      cardholderNameCtrl.dispose();

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

  void _showEditPaymentDialog(
    BuildContext context,
    PaymentMethodController controller,
    PaymentMethod method,
  ) {
    PaymentType selectedType = method.type;
    final expiryDateCtrl = TextEditingController(text: method.expiryDate);
    final cardholderNameCtrl = TextEditingController(text: method.cardholderName ?? '');
    bool setAsDefault = method.isDefault;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Payment Method"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<PaymentType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: "Card Type"),
                      items: PaymentType.values.map((type) {
                        String label;
                        switch (type) {
                          case PaymentType.visa:
                            label = 'Visa';
                            break;
                          case PaymentType.mastercard:
                            label = 'Mastercard';
                            break;
                          case PaymentType.amex:
                            label = 'American Express';
                            break;
                          case PaymentType.discover:
                            label = 'Discover';
                            break;
                          case PaymentType.paypal:
                            label = 'PayPal';
                            break;
                          case PaymentType.other:
                            label = 'Other';
                            break;
                        }
                        return DropdownMenuItem(value: type, child: Text(label));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedType = value);
                        }
                      },
                    ),
                    Text(
                      method.maskedCardNumber,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: expiryDateCtrl,
                      decoration: const InputDecoration(labelText: "Expiry Date (MM/YY)"),
                      maxLength: 5,
                    ),
                    TextField(
                      controller: cardholderNameCtrl,
                      decoration: const InputDecoration(labelText: "Cardholder Name (Optional)"),
                    ),
                    CheckboxListTile(
                      title: const Text("Set as default payment method"),
                      value: setAsDefault,
                      onChanged: (val) => setState(() => setAsDefault = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    expiryDateCtrl.dispose();
                    cardholderNameCtrl.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () async {
                    final error = await controller.updatePaymentMethod(
                      paymentId: method.id,
                      type: selectedType,
                      expiryDate: expiryDateCtrl.text,
                      cardholderName: cardholderNameCtrl.text.isEmpty
                          ? null
                          : cardholderNameCtrl.text,
                      setAsDefault: setAsDefault != method.isDefault ? setAsDefault : null,
                    );

                    expiryDateCtrl.dispose();
                    cardholderNameCtrl.dispose();

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
    BuildContext context,
    PaymentMethodController controller,
    String paymentId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Payment Method"),
        content: const Text("Are you sure you want to delete this payment method?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await controller.deletePaymentMethod(paymentId);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
