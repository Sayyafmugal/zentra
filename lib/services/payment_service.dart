import '../models/order.dart';

/// The outcome of asking a [PaymentService] to collect payment for an order.
class PaymentResult {
  const PaymentResult({required this.success, required this.resultingStatus, this.failureReason});

  final bool success;
  final PaymentStatus resultingStatus;
  final String? failureReason;
}

/// Abstracts "how does this order get paid for" away from checkout and
/// order-creation so a real gateway (Stripe, PayPal, etc.) could be dropped
/// in later without touching either — bind a different implementation in
/// InitialBinding rather than changing call sites.
///
/// Only two implementations exist, and both are honest about what they
/// actually do: neither moves real money, because no payment processor
/// credentials are configured for this project (see the top-level "no
/// Firebase Storage / no paid infra" constraint this app was built under).
abstract class PaymentService {
  /// Shown to the customer at checkout — must make it obvious when a method
  /// doesn't perform a real charge.
  String get label;

  Future<PaymentResult> charge({required double amount, String? paymentMethodId});
}

/// The one genuinely real payment path in this app: nothing is charged
/// electronically at all. The order is placed with [PaymentStatus.pending]
/// and cash changes hands at delivery, which is exactly what "Cash on
/// Delivery" means — there's no gap between what this claims to do and what
/// it does.
class CashOnDeliveryPaymentService implements PaymentService {
  @override
  String get label => 'Cash on Delivery';

  @override
  Future<PaymentResult> charge({required double amount, String? paymentMethodId}) async {
    return const PaymentResult(success: true, resultingStatus: PaymentStatus.pending);
  }
}

/// Simulates a card charge with no real payment processor behind it — there
/// is no Stripe/PayPal integration in this project. This exists only to let
/// a reviewer see a complete "online payment" checkout path; every place it
/// is offered in the UI must label it Demo/Sandbox so nobody mistakes it for
/// a working integration. It never fails and never actually moves money.
class DemoCardPaymentService implements PaymentService {
  @override
  String get label => 'Card (Demo — no real charge is made)';

  @override
  Future<PaymentResult> charge({required double amount, String? paymentMethodId}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const PaymentResult(success: true, resultingStatus: PaymentStatus.paid);
  }
}
