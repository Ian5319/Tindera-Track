# TinderaTrack User Manual

## 1. Purpose

TinderaTrack helps a store owner track products, stock, cash sales, customer
Utang, repayments, and sales summaries from one account. Store data is synchronized
through Firebase and is visible only to the signed-in owner account.

## 2. Getting started

### Create an account

1. Open TinderaTrack and select **Create Account**.
2. Enter a username and a valid email address. The username must be 3–32 characters
   using letters, numbers, dots, underscores, or hyphens.
3. Create a password with at least eight characters containing letters, numbers,
   and a symbol.
4. Select **Create Account**. The app creates the owner profile and opens the
   dashboard.

### Log in

1. Enter the registered email address and password.
2. Select **Log In**.
3. If the password is forgotten, select **Forgot Password?**, enter the account
   email, and follow the email instructions. For privacy, the reset dialog does not
   reveal whether an email is registered.

TinderaTrack signs the user out after 30 minutes without activity. It also starts
logged out whenever the application is reopened.

## 3. Navigation

The bottom navigation bar opens **Home**, **Inventory**, **Utang**, and **Reports**.
The menu button in the upper-left opens the same destinations and the **Log out**
action. Swipe down on data lists to refresh them from Firebase.

## 4. Dashboard

The Home dashboard shows:

- today's cash and Utang sales;
- the number of products at or below their low-stock threshold;
- total outstanding customer Utang; and
- shortcuts for adding a product or recording an Utang sale.

If part of the dashboard cannot be loaded, a warning appears because displayed
totals may be incomplete. Select **Retry** or pull down to refresh.

## 5. Inventory

### Add a product

1. Open **Inventory** and select **Add item**.
2. Take a product photo or choose one from the device gallery. A photo is optional.
3. Enter the product name, selling price, starting stock, and low-stock threshold.
4. Select **Save Item**.

Photos must be JPEG, PNG, or WebP and smaller than 5 MB. Gallery images are resized
before upload where the platform supports it.

### Find and open a product

Use **Search products** to filter the inventory by name. Select a product to open
Product Management, where current price, stock, threshold state, and sales history
are displayed.

### Edit product details

1. Open the product.
2. Select the edit icon in the app bar.
3. Change the name, selling price, or low-stock threshold.
4. Select **Save changes**.

Stock is changed separately so stock movements remain intentional.

### Add or remove stock

1. Open the product.
2. Select **Add stock** or **Remove stock**.
3. Enter a whole-number quantity greater than zero.

The app prevents stock from becoming negative.

### Record a cash sale

1. Open the product and select **Record sale**.
2. Enter the quantity sold.
3. Confirm with **Sell**.

The sale and stock deduction are saved in one Firestore transaction. A sale cannot
be recorded when there is insufficient stock.

### Delete a product

Open the product and select the delete icon. Deleting removes it from active
inventory; previously recorded sales remain available for reports. Product-photo
cleanup is attempted after the inventory record is removed.

## 6. Utang

### Record an Utang sale

1. Open **Utang** and select **Record utang**.
2. Choose an existing customer from the customer-name menu, or enter a new customer
   name and optional phone number.
3. Review the current remaining balance. This includes earlier payments.
4. Enter the new Utang amount. **Balance after entry** updates immediately.
5. Add an optional note.
6. Select **Save Utang Sale**.

The new customer and Utang record are synchronized to Firebase.

### Find a customer

Use **Search customers** to filter by customer name or phone number. Each customer
card displays the remaining balance after payments. Select a customer to view the
full Utang and payment history.

### Record a payment

1. Open a customer and select **Record Payment**.
2. Enter an amount no greater than the remaining balance.
3. Optionally change the payment date and add a note.
4. Select **Record Payment**.

Partial payments are supported. The status changes between **UNPAID**,
**PARTIALLY PAID**, and **PAID**. A generated request ID prevents a double tap or
retry from creating a duplicate payment.

### Edit or delete a payment

Use the edit or delete icon beside a payment. An edited amount cannot exceed the
balance that was available before that payment. Deletion requires confirmation and
immediately restores the amount to the remaining balance.

### Remove a paid customer

When a customer's remaining balance reaches zero, use the delete action on the
customer card to remove the customer from the active Utang list. Transaction and
payment records are retained for historical reporting.

## 7. Reports

Reports combine cash-product sales and Utang sales.

- **Daily** shows the current week by day.
- **Weekly** shows totals for the latest five weeks.
- **Total Sales** is the combined recorded sales total.
- **Outstanding Utang** is the remaining balance for active customers.
- **Top-Selling Products** ranks products by recorded cash-sale quantity.

Pull down to refresh. If a data source cannot be loaded, the screen warns that
totals may be incomplete.

## 8. Data entry limits

- Money must be positive and no greater than ₱1,000,000,000,000.
- Quantities and thresholds must be whole numbers from 0 to 1,000,000,000.
- Product and customer names are limited to 200 characters.
- Phone numbers are limited to 32 characters.
- Notes are limited to 2,000 characters.
- Photos must be JPEG, PNG, or WebP and smaller than 5 MB.

## 9. Troubleshooting

### The app says Firebase is not configured

The selected platform has no Firebase application configuration. Use Android, iOS,
or Web, or ask the administrator to add the platform through FlutterFire.

### Data does not load

Check internet access, confirm the correct account is signed in, then pull down or
select **Retry**. If newly deployed security rules reject older records, an
administrator must migrate those documents to include the correct `ownerId`.

### Camera or gallery does not open

Grant camera/photo permission in device settings. On an emulator without a camera,
use **Choose photo**. A file over 5 MB must be resized before upload.

### A sale cannot be recorded

Confirm the requested quantity is greater than zero and does not exceed current
stock.

### A payment cannot be recorded

Confirm the amount is positive and does not exceed the displayed remaining balance.

## 10. Privacy and account safety

- Do not share the owner password.
- Log out before handing the device to another person.
- Customer names, phone numbers, balances, and photos are store-owner data; collect
  and retain them only with an appropriate business purpose.
- Firebase project administrators can access backend data and should use least-
  privilege accounts and multi-factor authentication.
