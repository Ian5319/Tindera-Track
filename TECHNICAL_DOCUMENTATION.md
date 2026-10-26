# TinderaTrack Technical Documentation

## 1. System overview

TinderaTrack is a Flutter/Material 3 client backed by Firebase Authentication,
Cloud Firestore, and Firebase Storage. The application is organized into
presentation, provider, repository/data-source, model, and service layers.

Supported Firebase configurations are Android, iOS, and Web. macOS, Windows, and
Linux targets compile the Flutter shell but display a controlled configuration
message until Firebase options are generated for those platforms.

## 2. Technology stack

- Flutter and Dart (`>=3.2.0 <4.0.0`)
- Provider for authenticated application state
- GoRouter for guarded navigation
- Firebase Authentication for email/password identity
- Cloud Firestore for user, inventory, sales, customer, Utang, and payment records
- Firebase Storage for owner-scoped product photos and compatible access to legacy
  Utang attachments
- camera and image_picker for image capture/selection
- intl for Philippine Peso and date formatting

## 3. Source organization

```text
lib/
  core/                 themes, constants, formatting, validation
  data/
    models/             application data objects
    data_sources/       Firestore payment implementation
    repositories/       authentication, inventory, sales, Utang, payments
  presentation/
    providers/          state, loading/error handling, request de-duplication
    routes/             guarded GoRouter configuration
    screens/            feature screens
    widgets/            reusable UI and feature components
  services/             camera, payment orchestration, media storage
```

Dependency direction is presentation → provider → repository/data source → Firebase.
Widgets do not directly issue Firestore writes. Media uploads are handled by
`MediaStorageService`, while payment validation/idempotency is coordinated by
`PaymentService`.

## 4. Startup and dependency wiring

`main.dart` initializes Flutter bindings and the platform Firebase application. A
Firebase configuration failure renders a controlled error app instead of crashing.
`buildAppProviders` creates the authentication provider and authenticated inventory,
Utang, and payment providers.

`ChangeNotifierProxyProvider` propagates authentication state. On login, each data
provider schedules its initial load. On logout, cached owner data, loading state, and
errors are cleared. Provider load futures are de-duplicated so simultaneous screen
requests share one active network request.

## 5. Authentication and session lifecycle

- Login uses normalized email plus Firebase password authentication.
- Sign-up requires 8–128 characters with letters, numbers, and a symbol.
- The Firestore profile is created only under the authenticated UID.
- If profile creation fails, the partial authenticated session is signed out.
- Password reset is email-only and intentionally does not disclose whether an
  account exists.
- Every launch begins logged out.
- Authenticated sessions expire after 30 minutes without pointer or keyboard
  activity.
- GoRouter redirects unauthenticated access to `/login` and prevents authenticated
  users from returning to authentication screens.

## 6. Routes

| Route | Purpose |
| --- | --- |
| `/login` | Account login and password reset |
| `/signup` | Account creation |
| `/home` | Store dashboard |
| `/inventory` | Product search and low-stock list |
| `/inventory/add` | Product creation and photo upload |
| `/inventory/product/:id` | Product editing, stock, sale, and history |
| `/utang` | Customer search and outstanding balances |
| `/utang/record` | New Utang entry |
| `/utang/customer/:id` | Customer balance and complete history |
| `/utang/customer/:id/payment` | Payment management |
| `/reports` | Daily/weekly reports and product ranking |

Unknown routes render a recoverable page with a Home action.

## 7. Firestore data model

All business collections include an `ownerId` equal to the authenticated Firebase
UID. Dates are stored as Firestore timestamps.

### `users/{uid}`

`id`, `name` (the account username), `nameLowercase`, `email`, `phone`, `storeName`,
`createdAt`

The user may read and update only their own profile. Identity fields and creation
time are protected by rules.

### `products/{productId}`

`id`, `ownerId`, `name`, `price`, `stockQuantity`, `photoUrl`, `threshold`,
`createdAt`, `updatedAt`

Product creation/editing uses `set`. Stock adjustments run in a Firestore
transaction and prevent negative stock.

### `sales/{saleId}`

`id`, `ownerId`, `productId`, `productName`, `quantity`, `sellingPrice`,
`totalAmount`, `soldAt`

Sale creation and product stock deduction are committed in the same Firestore
transaction. Sale records are immutable and retained if a product is deleted.

### `customers/{customerId}`

`id`, `ownerId`, `name`, `phone`, `balance`, `createdAt`, `updatedAt`

The client calculates the current gross Utang balance from immutable Utang
transactions rather than trusting the stored compatibility field.

### `utang_transactions/{transactionId}`

`id`, `ownerId`, `customerId`, `amount`, `type`, `photoUrl`, `note`, `createdAt`

`type` is `credit` or `payment`. Current screens create credits here and maintain
new repayments in `payment_records`. Transactions are immutable.

### `payment_records/{paymentId}`

`id`, `ownerId`, `customerId`, `customerName`, `utangId`, `amount`, `paymentDate`,
`note`, `recordedBy`, `createdAt`, `updatedAt`

Create requests use a stable request ID. Repeating an identical request returns the
existing payment, while a conflicting reuse is rejected. Update preserves ownership,
customer identity, recorder, and creation time.

## 8. Storage layout

```text
users/{uid}/products/{productId}.{extension}
users/{uid}/utang/{transactionId}.{extension}
```

Only the matching authenticated UID can read, write, or delete these objects.
Uploads are restricted to JPEG, PNG, or WebP under 5 MB. The client verifies size
before loading/uploading and stores only HTTPS download URLs in Firestore. Local
device paths are never persisted as remote record URLs.

## 9. Security controls

The canonical rules are `firestore.rules` and `storage.rules`, referenced by
`firebase.json`.

- Default-deny fallback for unknown Firestore documents and Storage paths
- Per-owner reads and writes using `request.auth.uid`
- Strict field allowlists and required fields
- Type, length, numeric range, timestamp, and HTTPS URL validation
- Immutable ownership and creation fields
- Referenced customer/product ownership checks
- Immutable sale and Utang transaction history
- Owner-only profile access, preventing public customer/account lookup
- Email-only reset flow with reduced account enumeration
- No passwords, PINs, customer records, or business records in local Hive storage

Firebase client API keys are public project identifiers and are expected in mobile
and web builds. Service-account credentials and private keys must never be included
in this repository.

### Business-invariant note

The trusted client validates that a payment does not exceed the displayed remaining
balance. Firestore rules independently enforce owner access, schema, and positive
amounts, but Firestore rules cannot aggregate every prior payment. If the threat
model includes hostile modified clients, move payment creation to a callable Cloud
Function or another trusted transactional ledger that maintains an authoritative
per-customer balance.

## 10. Performance and resilience

- Inventory, sales, customer, transaction, and payment reads are filtered by owner.
- Customer and Utang transaction snapshots load concurrently.
- Customer balances are calculated in one in-memory pass, replacing per-customer
  recalculation reads/writes.
- Provider-level in-flight futures prevent duplicate simultaneous loads.
- Independent dashboard refreshes execute concurrently.
- Images use Flutter's image cache; gallery images are resized before upload.
- Firestore values are parsed defensively so malformed optional fields use safe
  defaults instead of unchecked casts.
- Loading, retry, empty, and partial-data warnings are visible on major screens.

The current reports intentionally load the owner's complete history to calculate
all-time totals. For stores with very large histories, add cursor pagination and
server-maintained daily aggregates before the collection reaches a size where a
full history read is costly.

## 11. Local development

```bash
flutter pub get
flutter run
```

Use a physical device for full camera verification. An Android emulator can use the
gallery fallback.

### Firebase configuration

The project includes generated options for Android, iOS, and Web. To bind another
Firebase project or add a desktop target:

```bash
flutterfire configure
```

Regenerate and review `firebase_options.dart` plus platform configuration before
committing. Ensure Android `applicationId` and iOS bundle identifier match their
Firebase applications.

## 12. Testing and builds

```bash
flutter test --no-pub
flutter build apk --debug --no-pub
```

Before release, also run:

```bash
flutter analyze --no-pub
flutter build apk --release
```

Use `TESTING_CHECKLIST.md` for device acceptance tests. Camera, permission, network,
password-reset email delivery, and Firebase rules require a configured device or
emulator and cannot be fully covered by local widget tests.

## 13. Existing-data migration

Do not deploy the owner-isolating rules over legacy documents until migration is
complete.

1. Export or back up Firestore.
2. Determine the correct Firebase UID for every legacy store.
3. Add that UID as `ownerId` to its products, sales, customers,
   `utang_transactions`, and `payment_records`.
4. Ensure payment `recordedBy` contains the same trusted UID.
5. Confirm required IDs, timestamps, numeric fields, and nullable fields match the
   schemas above.
6. Test with the Firestore emulator or a staging project.
7. Deploy rules and verify two test owners cannot read each other's data.

## 14. Deployment

Deploy the complete rules from the repository root:

```bash
firebase deploy --only firestore:rules,storage
```

Then build/sign the desired client. Deployment of rules changes production access
immediately; use a staging project and backup for the first migration.

## 15. Operational troubleshooting

- **Permission denied:** verify authentication, `ownerId`, required fields, and that
  the complete `firebase.json` rules were deployed.
- **Photo upload rejected:** verify ownership path, content type, and 5 MB size.
- **Product sale rejected:** confirm the product still exists, belongs to the user,
  and has enough stock.
- **Composite index prompt:** follow the Firebase console link only after reviewing
  that the query is owner-scoped; record the resulting index configuration in source
  control.
- **Desktop configuration screen:** generate Firebase options for that platform or
  run an already configured target.
- **Legacy records disappear after rules deployment:** restore/stage from backup and
  complete `ownerId` migration; do not weaken the production rules.

## 16. Backup and recovery

Use scheduled Firestore exports and Firebase Storage retention appropriate to the
business. Test restore procedures in a separate project. Deleting an active product
or paid customer does not delete immutable sales, Utang transactions, or payment
history, but application-level deletion is not a substitute for backend backups.
