# Zentra

A modern e-commerce storefront built with Flutter and Firebase — browse a product catalog, manage a cart and wishlist, check out, track orders, and (for seller/admin accounts) manage a multi-seller marketplace catalog.

Live demo: https://zentra-0.vercel.app

## Features

- **Auth** — email/password sign up, sign in, and password reset via Firebase Auth, with real form validation.
- **Roles** — `user` / `seller` / `admin`, enforced by Firestore security rules (not just hidden UI) — a client can never self-grant seller/admin access.
- **Catalog** — browsable/searchable product grid with category filters, product variants (size/color) with per-variant stock, responsive column counts, and skeleton loading states.
- **Cart & Wishlist** — add to cart with size selection, quantity stepper, move-to-cart from wishlist.
- **Checkout & Orders** — transactional checkout (re-validates prices/stock/coupons server-side), "Buy Now" for a single item independent of the cart, coupon codes, cash-on-delivery or demo card payment, a real 11-state fulfillment lifecycle with enforced status transitions, order history, per-order status tracking.
- **Reviews** — delivery-gated: a customer can review a product only from an order that was actually delivered to them, one review per order+product; submitting one atomically updates the product's running rating.
- **Notifications** — generated from real order status changes rather than static mock data.
- **Account** — editable profile, dark mode, privacy policy / terms screens.
- **Seller marketplace** — apply to become a seller, admin approval queue, seller dashboard for managing your own products and fulfilling your own orders; a suspended seller instantly loses write access.
- **Admin dashboard** — role-gated (Firestore-enforced) management for products, sellers, categories, and coupons, plus an audit log of sensitive admin actions.
- **Home vs. Shopping** — Home is a curated discovery landing page (promo, categories, New Arrivals / Popular rails); Shopping is the full searchable/filterable catalog. Both read the same product feed rather than duplicating fetch logic.
- **Light & dark themes** — a single design-system theme (colors, typography, spacing) applied consistently across every screen.

## Tech stack

- **Flutter** (Web, with Android/iOS/desktop targets available)
- **GetX** for state management and navigation (named routes, no ad-hoc widget pushes)
- **Firebase**: Auth, Cloud Firestore — **no Firebase Storage** (see Images below)
- **cached_network_image**, **lottie**, **shimmer** for media and polish

## Images

This project intentionally does not use Firebase Storage (it requires the Blaze billing plan to enable at all). Product and profile images are plain URLs — pasted in directly today via `lib/services/image_storage_service.dart`'s `ImageStorageService` abstraction. To add real file uploads later, implement that interface against a provider (Cloudinary, ImgBB, S3, etc.) and bind it in `lib/bindings/initial_binding.dart`; no screen or controller needs to change.

## Architecture

```
lib/
  models/        Typed data models (Equatable, fromJson/toJson)
  repositories/   One class per Firestore collection — the only layer that talks to Firestore
  Controllers/    GetX controllers: reactive state + orchestration, no direct Firestore calls
  services/       Provider-agnostic abstractions (e.g. ImageStorageService)
  routes/         Named route table (AppRoutes/AppPages) + admin route middleware
  bindings/       Dependency injection setup
  widgets/        Shared, reusable UI components (buttons, cards, loading/empty states)
  view/           Screens
  Utils/          Theme, color tokens, spacing scale, responsive breakpoints
```

Firestore access rules live in `firestore.rules` (public product reads, per-user data isolation, seller-owns-own-products, admin-only escalation), version-controlled and deployed via the Firebase CLI:

```
firebase deploy --only firestore:rules
```

## Security

Authorization is enforced by **Firestore Security Rules**, not by hiding buttons in the UI. `AdminMiddleware`/`SellerOrAdminMiddleware` (`lib/routes/admin_middleware.dart`) redirect unauthorized users away from admin/seller screens for a clean UX, but the actual boundary is `firestore.rules`, independently checked on every read/write regardless of what the client sends:

- A user can never self-grant `role` — only an existing admin can promote/demote an account.
- A seller's writes are scoped to their own products and to orders that contain only their own items; a suspended seller (`sellers/{uid}.status != 'active'`) loses write access immediately, even before any role field is rolled back.
- Order status transitions are validated server-side against the same state machine the app uses client-side (`kValidOrderStatusTransitions` / `kSellerAllowedOrderTransitions` in `lib/models/order.dart`) — a client cannot jump an order to an arbitrary status.
- A review can only be created for a product from that user's own `delivered` order, one review per order+product.
- Checkout is a Firestore transaction that re-reads live product prices/stock and re-validates any coupon server-side — nothing about the total or availability is trusted from the client (see `OrderRepository.createOrderFromCart`).

This project deliberately has no Cloud Functions, so a couple of aggregate counters (`coupons.usedCount`, a product's `rating`/`reviewCount`) are only *shape-bounded* in the rules (a client can update them, but only by exactly the amount a real redemption/review would produce) rather than fully tamper-proof. Closing that gap completely would require server-side Cloud Functions, which is out of scope for this project by design — see Limitations below.

## Limitations

Honest, intentional scope boundaries — not oversights:

- **Payment.** Cash on Delivery is the one fully "real" payment path (no money is meant to move electronically). "Pay with Card" is a clearly labeled **demo/simulated** flow (`DemoCardPaymentService`) — there is no Stripe/PayPal/other real payment gateway integrated, and the UI says so at the point of choosing it.
- **Images.** No Firebase Storage (it requires the paid Blaze plan). Product and profile images are pasted URLs, validated and rendered with a loading placeholder and a broken-image fallback (`lib/widgets/product_image.dart`) rather than a real upload pipeline.
- **Backend architecture.** No Cloud Functions, by design — every rule the app relies on runs client-triggerable but rule-validated writes instead of trusted server code. The audit log is therefore best-effort (write failures are swallowed so they never block the real action), and the two aggregate counters noted above are shape-bounded rather than cryptographically verified.
- **Buy Now.** Fixed: selecting a product, choosing a variant, and tapping "Buy Now" now checks out exactly that item through the same secure transactional pipeline as a normal cart checkout, without reading or modifying the user's actual cart (`OrderController.createOrderFromItems`, wired through `CheckoutScreen.isBuyNow`).

## Getting started

```bash
flutter pub get
flutter run -d chrome   # or any other configured device
```

The app expects a Firebase project configured in `lib/firebase_options.dart`. To seed sample catalog data, sign in with an admin account (`role: 'admin'` on that user's `users/{uid}` Firestore document) and use the "Seed sample catalog data" action on the Seller Dashboard.

## Testing

```bash
flutter test
```

Covers model serialization/equality (including backward-compatible decoding of pre-upgrade Firestore documents), repository behavior against `fake_cloud_firestore`, order status transition rules, cart/order business logic, and key shared widgets.
