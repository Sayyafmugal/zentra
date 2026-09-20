/// Flat-rate shipping and tax shared between the checkout preview
/// (CheckoutScreen) and the authoritative total computed inside
/// OrderRepository.createOrderFromCart's transaction. A single source so the
/// price a customer sees/pays at checkout can never drift from what's
/// actually persisted on the order.
const double kFlatShippingFee = 10.0;
const double kTaxRate = 0.08; // applied to subtotal + shipping
