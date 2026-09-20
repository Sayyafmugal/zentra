import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/order.dart';
import 'package:zentra_0/services/payment_service.dart';

void main() {
  group('CashOnDeliveryPaymentService', () {
    test('always succeeds and leaves payment pending until delivery', () async {
      final service = CashOnDeliveryPaymentService();

      final result = await service.charge(amount: 50.0);

      expect(result.success, isTrue);
      expect(result.resultingStatus, PaymentStatus.pending);
    });

    test('label makes clear no money moves electronically', () {
      expect(CashOnDeliveryPaymentService().label, contains('Cash on Delivery'));
    });
  });

  group('DemoCardPaymentService', () {
    test('succeeds and reports paid, but is clearly labeled as a demo', () async {
      final service = DemoCardPaymentService();

      final result = await service.charge(amount: 50.0, paymentMethodId: 'pm1');

      expect(result.success, isTrue);
      expect(result.resultingStatus, PaymentStatus.paid);
      expect(service.label.toLowerCase(), contains('demo'));
    });
  });
}
