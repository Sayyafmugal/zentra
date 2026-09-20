# Zentra

A modern e-commerce storefront built with Flutter and Firebase — browse a product catalog, manage a cart and wishlist, check out, track orders, and (for seller/admin accounts) manage a multi-seller marketplace catalog.

Live demo: _add your deployed Vercel URL here_

## Features

- **Auth** — email/password sign up, sign in, and password reset via Firebase Auth, with real form validation.
- **Roles** — `user` / `seller` / `admin`, enforced by Firestore security rules (not just hidden UI) — a client can never self-grant seller/admin access.
- **Catalog** — browsable/searchable product grid with category filters, product variants (size/color) with per-variant stock, responsive column counts, and skeleton loading states.
- **Cart & Wishlist** — add to cart with size selection, quantity stepper, move-to-cart from wishlist.
- **Checkout & Orders** — address and payment method management, order placement with a real 11-state fulfillment lifecycle and enforced status transitions, order history, per-order status tracking.
- **Notifications** — generated from real order status changes rather than static mock data.
- **Account** — editable profile, dark mode, privacy policy / terms screens.
- **Admin dashboard** — role-gated (Firestore-enforced) product management: add, edit, and delete products.
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
