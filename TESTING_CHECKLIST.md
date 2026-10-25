# TinderaTrack Release Testing Checklist

Use a staging Firebase project containing two owner accounts. Do not run destructive
tests against the only production copy of store data.

## Automated gates

- [x] `flutter test --no-pub` passes (13 tests, verified 2026-10-26)
- [x] `flutter analyze --no-pub` completes without errors (verified 2026-10-26)
- [x] `flutter build apk --debug --no-pub` succeeds (verified 2026-10-26)
- [x] `git diff --check` reports no whitespace errors (verified 2026-10-26)
- [x] `firebase.json`, platform JSON, and plist configuration parse correctly
      (verified 2026-10-26)
- [x] Firestore rules compile and deploy successfully to `tinderatrack-acf1a`
      (verified 2026-10-26)
- [ ] Storage rules compile in the emulator or staging deployment

## Authentication and session

- [ ] App opens on Login without crashing
- [ ] Invalid email and short password are rejected locally
- [ ] Account creation enforces password complexity
- [ ] Valid sign-up creates both Firebase Auth user and Firestore profile
- [ ] Failed profile creation leaves no active local session
- [ ] Valid login opens Home
- [ ] Incorrect login uses a generic email/password error
- [ ] Password reset gives the same success response for registered/unregistered email
- [ ] Protected deep links redirect a logged-out user to Login
- [ ] Logout clears Inventory, Utang, and Payment provider state
- [ ] Thirty minutes of inactivity expires the session

## Dashboard and navigation

- [ ] Home, Inventory, Utang, and Reports switch from bottom navigation
- [ ] Drawer routes match bottom navigation and Logout requires confirmation
- [ ] Dashboard totals match Firestore records
- [ ] Pull-to-refresh updates all dashboard data
- [ ] Partial-load failure displays a warning and Retry
- [ ] Unknown route displays Page not found and Return home works

## Inventory

- [ ] Empty inventory shows first-product guidance
- [ ] Product search filters by name
- [ ] Add item works with no photo, camera photo, and gallery photo
- [ ] Image over 5 MB is rejected with a useful message
- [ ] Name, price, stock, and threshold validation is enforced
- [ ] Saved product appears without reopening the app
- [ ] Low-stock threshold changes the product visual state
- [ ] Product name, price, and threshold can be edited
- [ ] Add stock increases stock by the entered quantity
- [ ] Remove stock cannot create negative stock
- [ ] Record sale atomically decreases stock and adds sales history
- [ ] Sale greater than stock is rejected
- [ ] Product deletion removes the active product and retains sales history
- [ ] Pull-to-refresh reloads inventory and sales

## Utang and payments

- [ ] Empty customer list shows guidance
- [ ] Customer search matches name and phone
- [ ] Existing customer selection shows remaining balance after payments
- [ ] New amount updates Balance after entry immediately
- [ ] New customer name/phone limits are enforced
- [ ] Record Utang has no photo capture/gallery controls and saves successfully
- [ ] Legacy photo evidence still opens in the customer history viewer
- [ ] Utang charge increases gross customer balance
- [ ] Customer history displays amount, date, note, and attachment state
- [ ] Payment cannot exceed the remaining balance
- [ ] Repeated payment submission with the same request ID does not duplicate data
- [ ] Partial payment updates amount and status
- [ ] Payment edit recalculates remaining balance
- [ ] Payment delete restores remaining balance
- [ ] Fully paid customer can be removed from active list
- [ ] Customer with a positive remaining balance cannot be removed
- [ ] Pull-to-refresh reloads customers and payments

## Reports

- [ ] Daily chart labels and values cover the current Monday–Sunday week
- [ ] Weekly chart covers the latest five weeks
- [ ] Total Sales combines cash and Utang sales
- [ ] Outstanding Utang matches active customer balances after payments
- [ ] Top-Selling Products ranks cash-sale quantity correctly
- [ ] Empty sales history displays the empty state
- [ ] Pull-to-refresh and Retry update report values

## Security acceptance

- [ ] Owner A cannot read/write Owner B users, products, customers, sales,
      transactions, payments, or photos
- [ ] Unauthenticated reads and writes are denied
- [ ] Unknown collections and Storage paths are denied
- [ ] Extra fields, invalid types, negative amounts, oversized strings, and future
      timestamps are rejected where prohibited by rules
- [ ] Product photo uploads reject disallowed type or size
- [ ] Sale/transaction immutable fields cannot be edited by the client
- [ ] No password, PIN, service-account key, or private key exists in source/local data

## Device and accessibility acceptance

- [ ] Android small phone layout (approximately 360 × 640) has no overflow
- [ ] Android large phone/tablet layout has no overflow
- [ ] iOS camera and photo-library permission prompts contain clear descriptions
- [ ] Web login, inventory, Utang, and reports work on a supported browser
- [ ] Primary actions are at least 48 logical pixels high
- [ ] Text remains usable at 200% text scaling
- [ ] Screen-reader labels/tooltips identify icon-only actions
- [ ] Keyboard navigation and form submission work on Web
- [ ] Offline/network failure returns a recoverable error rather than a crash

## Release sign-off

- [ ] Legacy documents have been backed up and migrated with correct `ownerId`
- [ ] Rules were tested in staging before production deployment
- [ ] Release APK/App Bundle is signed with the intended application ID
- [ ] Password-reset email template and authorized domains are configured
- [ ] Privacy notice, retention policy, support contact, and backup schedule are approved
- [ ] User manual and technical documentation match the release commit
