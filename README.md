# TinderaTrack Flutter MVP

TinderaTrack is a Material 3 Flutter MVP for sari-sari store owners, focused on fast inventory tracking and photo-verified utang records.

## Implemented core journey

1. Local login with auto-session and demo credentials.
2. Create Account flow with password validation.
3. Dashboard: today's sales, low-stock alerts, outstanding utang, quick actions.
4. Inventory search/filter, low-stock highlighting, add/edit item flow with camera or gallery fallback.
5. Utang recording with customer selector, live balance preview, required photo attachment, and Hive persistence.
6. Customer balance/history with charge (+) and payment (-) indicators, plus fixed Record Payment action.
7. Daily/Weekly reports with custom-painted bar chart, KPI cards, and top-selling products.
8. Bottom navigation for Home, Inventory, Utang, and Reports.

## Storage and packages

- Provider for state management
- Hive + hive_flutter for local inventory, customer, transaction, user, and session data
- camera for product capture
- image_picker for gallery and utang photo attachment
- GoRouter for navigation
- intl for Philippine Peso and date formatting
- Material 3 styling with warm Filipino/market-inspired orange, green, and amber tones

The local storage is intentionally MVP/demo-grade. Production deployment should add a real authentication backend, secure credential handling, encrypted storage, cloud photo sync, and robust offline conflict resolution.

## Demo credentials

Phone: `09171234567`
PIN: `1234`

## Run on Android

1. Install Flutter and Android Studio/SDK.
2. Run `flutter pub get`.
3. Connect an Android emulator or device.
4. Run `flutter run`.

On the first Android run, grant camera permission when prompted. If an emulator has no usable camera, the Add Inventory screen exposes a gallery fallback so the end-to-end flow remains demonstrable.

## Phase 1 note

The supplied Phase 1 document says self-service account creation is out of scope for Phase 1, while the requested MVP specification explicitly requires a Create Account screen. This implementation follows the current MVP specification and includes Create Account as a local demo flow.
