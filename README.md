# TinderaTrack Flutter MVP

TinderaTrack is a Material 3 Flutter MVP for sari-sari store owners, focused on fast inventory tracking and photo-verified utang records.

## Implemented core journey

1. Firebase Authentication login with an email/password account.
2. Create Account flow with password validation.
3. Dashboard: today's sales, low-stock alerts, outstanding utang, quick actions.
4. Inventory search/filter, low-stock highlighting, add/edit item flow with camera or gallery fallback.
5. Utang recording with customer selector, live balance preview, and Firestore persistence.
6. Customer balance/history with charge (+) and payment (-) indicators, plus fixed Record Payment action.
7. Daily/Weekly reports with custom-painted bar chart, KPI cards, and top-selling products.
8. Bottom navigation for Home, Inventory, Utang, and Reports.

## Storage and packages

- Provider for state management
- Firebase Authentication and Cloud Firestore for account and store data
- Firebase Storage for owner-scoped product photos
- camera for product capture
- image_picker for gallery product photos
- GoRouter for navigation
- intl for Philippine Peso and date formatting
- Material 3 styling with warm Filipino/market-inspired orange, green, and amber tones

No passwords, PINs, customer records, or business data are stored in Hive. Existing
Firestore records created before owner isolation was added must be migrated by a
trusted administrator to include the correct `ownerId` before deploying the new
rules.

## Run on Android

1. Install Flutter and Android Studio/SDK.
2. Run `flutter pub get`.
3. Connect an Android emulator or device.
4. Run `flutter run`.

On the first Android or iOS camera use, grant camera permission when prompted. If an emulator has no usable camera, the Add Inventory screen exposes a gallery fallback so the end-to-end flow remains demonstrable.

## Deploy Firestore rules

The payment-history screen reads `payment_records`, which is protected by the
canonical `firestore.rules` file. Product photos use the checked-in
`storage.rules`. After signing in with the Firebase CLI, run
`firebase deploy --only firestore:rules,storage` from this directory. The
checked-in `.firebaserc` binds that command to the `tinderatrack-acf1a` project.

## Phase 1 note

The supplied Phase 1 document says self-service account creation is out of scope for Phase 1, while the requested MVP specification explicitly requires a Create Account screen. This implementation follows the current MVP specification and includes Create Account as a local demo flow.
