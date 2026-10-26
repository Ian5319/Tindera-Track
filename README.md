# TinderaTrack

TinderaTrack is a Flutter application for sari-sari store owners. It combines
inventory, cash-sale recording, customer Utang, payment history,
and sales reporting in one Firebase-backed product.

## Product capabilities

- Username + email + password account creation and login, reset, logout, and
  idle-session expiry
- Owner-isolated inventory with product photos, stock adjustment, editing, deletion,
  low-stock alerts, sale recording, and per-product sales history
- Customer Utang recording with live balance previews, customer search, detailed
  history, and paid-customer cleanup
- Payment creation, editing, deletion, partial-payment status, and duplicate-submit
  protection
- Dashboard and daily/weekly sales reports backed by live store data
- Defensive loading, empty, error, retry, and unsupported-platform states

## Documentation

- [User manual](USER_MANUAL.md)
- [Technical documentation](TECHNICAL_DOCUMENTATION.md)
- [Release testing checklist](TESTING_CHECKLIST.md)

## Quick start

Prerequisites: a compatible Flutter SDK, Android Studio/Android SDK or Xcode,
and access to the configured Firebase project.

```bash
flutter pub get
flutter run
```

Firebase is configured for Android, iOS, and Web. The desktop targets display a
configuration message until desktop Firebase applications are added with the
FlutterFire CLI.

## Verification

```bash
flutter test --no-pub
flutter build apk --debug --no-pub
```

## Firebase deployment

Existing documents created before owner isolation was introduced must first be
migrated by a trusted administrator so each document has the correct `ownerId`.
After migration, deploy the checked-in Firestore and Storage rules:

```bash
firebase deploy --only firestore:rules,storage
```

Do not deploy `firebase.payment.json` by itself for the main application. The
canonical configuration is [firebase.json](firebase.json), which uses the complete
rule set in [firestore.rules](firestore.rules).

Firebase mobile/web API keys in generated client configuration identify the
Firebase project; they are not service-account secrets. Access control is enforced
by Firebase Authentication plus the checked-in Firestore and Storage rules. Never
commit service-account JSON, private keys, or user passwords.
