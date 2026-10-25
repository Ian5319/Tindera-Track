import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer.dart';
import '../models/utang_transaction.dart';

class UtangRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customers =>
      _firestore.collection('customers');

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('utang_transactions');

  String get _ownerId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('An authenticated owner is required.');
    }
    return uid;
  }

  Query<Map<String, dynamic>> get _ownedCustomers =>
      _customers.where('ownerId', isEqualTo: _ownerId);

  Query<Map<String, dynamic>> get _ownedTransactions =>
      _transactions.where('ownerId', isEqualTo: _ownerId);

  Future<List<Customer>> getCustomers() async {
    final data = await loadData();
    return data.customers;
  }

  Future<({List<Customer> customers, List<UtangTransaction> transactions})>
      loadData() async {
    final snapshots = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      _ownedCustomers.get(),
      _ownedTransactions.get(),
    ]);

    final customerSnapshot = snapshots[0];
    final transactionSnapshot = snapshots[1];
    final transactions = transactionSnapshot.docs
        .map(_transactionFromFirestore)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final balances = <String, double>{};
    for (final transaction in transactions) {
      final signedAmount = transaction.type == UtangType.credit
          ? transaction.amount
          : -transaction.amount;
      balances[transaction.customerId] =
          (balances[transaction.customerId] ?? 0) + signedAmount;
    }

    final customers = customerSnapshot.docs.map((doc) {
      final customer = _customerFromFirestore(doc);
      final balance = balances[customer.id] ?? 0;
      return customer.copyWith(balance: balance < 0 ? 0 : balance);
    }).toList();

    customers.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return (customers: customers, transactions: transactions);
  }

  Future<Customer?> getCustomer(String id) async {
    final doc = await _customers.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final customer = _customerFromFirestore(doc);
    final balance = await currentBalance(id);
    return customer.copyWith(balance: balance);
  }

  Future<void> deleteCustomer(String id) async {
    final customerId = id.trim();
    if (customerId.isEmpty) {
      throw ArgumentError('Customer id cannot be empty.');
    }

    // Keep the related transactions and payments for reporting/history. The
    // customer is removed only from the active Utang list.
    await _customers.doc(customerId).delete();
  }

  // NEW: Create a customer manually.
  Future<Customer> createCustomer({
    required String name,
    String phone = '',
  }) async {
    final normalizedName = name.trim();
    final normalizedPhone = phone.trim();
    if (normalizedName.isEmpty || normalizedName.length > 200) {
      throw ArgumentError('A customer name must contain 1 to 200 characters.');
    }
    if (normalizedPhone.length > 32) {
      throw ArgumentError('A phone number cannot exceed 32 characters.');
    }

    final id = 'c${DateTime.now().microsecondsSinceEpoch}';

    final customer = Customer(
      id: id,
      ownerId: _ownerId,
      name: normalizedName,
      phone: normalizedPhone,
      balance: 0,
      createdAt: DateTime.now(),
    );

    await _customers.doc(id).set({
      'id': customer.id,
      'ownerId': customer.ownerId,
      'name': customer.name,
      'phone': customer.phone,
      'balance': customer.balance,
      'createdAt': Timestamp.fromDate(
        customer.createdAt,
      ),
      'updatedAt': Timestamp.now(),
    });

    return customer;
  }

  Future<List<UtangTransaction>> getTransactionsFor(
    String customerId,
  ) async {
    final snapshot = await _transactions
        .where(
          'ownerId',
          isEqualTo: _ownerId,
        )
        .where(
          'customerId',
          isEqualTo: customerId,
        )
        .get();

    final transactions = snapshot.docs.map(_transactionFromFirestore).toList();

    transactions.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return transactions;
  }

  Future<List<UtangTransaction>> getAllTransactions() async {
    final snapshot = await _ownedTransactions.get();
    final transactions = snapshot.docs.map(_transactionFromFirestore).toList();

    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return transactions;
  }

  Future<void> addTransaction(
    UtangTransaction transaction,
  ) async {
    if (transaction.id.trim().isEmpty ||
        transaction.customerId.trim().isEmpty ||
        !transaction.amount.isFinite ||
        transaction.amount <= 0 ||
        transaction.amount > 1000000000000 ||
        (transaction.note?.length ?? 0) > 2000 ||
        (transaction.photoUrl != null &&
            !transaction.photoUrl!.startsWith('https://'))) {
      throw ArgumentError('Transaction values are outside the allowed range.');
    }

    final customer = await _customers.doc(transaction.customerId).get();
    if (!customer.exists) {
      throw ArgumentError('The selected customer does not exist.');
    }

    if (transaction.type == UtangType.payment) {
      final balance = await currentBalance(transaction.customerId);
      if (transaction.amount > balance) {
        throw ArgumentError(
            'Payment cannot be greater than the current balance.');
      }
    }

    await _transactions.doc(transaction.id).set({
      'id': transaction.id,
      'ownerId': _ownerId,
      'customerId': transaction.customerId,
      'amount': transaction.amount,
      'type': transaction.type.name,
      'photoUrl': transaction.photoUrl,
      'note': transaction.note,
      'createdAt': Timestamp.fromDate(
        transaction.createdAt,
      ),
    });
  }

  Future<double> currentBalance(
    String customerId,
  ) async {
    final transactions = await getTransactionsFor(customerId);

    final balance = transactions.fold<double>(
      0,
      (total, transaction) =>
          total +
          (transaction.type == UtangType.credit
              ? transaction.amount
              : -transaction.amount),
    );

    return balance < 0 ? 0 : balance;
  }

  Customer _customerFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    final createdAt = data['createdAt'];

    return Customer(
      id: doc.id,
      ownerId: data['ownerId'] is String ? data['ownerId'] as String : '',
      name: data['name'] is String ? data['name'] as String : '',
      phone: data['phone'] is String ? data['phone'] as String : '',
      balance: data['balance'] is num ? (data['balance'] as num).toDouble() : 0,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  UtangTransaction _transactionFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final typeString =
        data['type'] is String ? data['type'] as String : 'credit';

    final type = typeString == UtangType.payment.name
        ? UtangType.payment
        : UtangType.credit;

    final createdAt = data['createdAt'];

    return UtangTransaction(
      id: doc.id,
      ownerId: data['ownerId'] is String ? data['ownerId'] as String : '',
      customerId:
          data['customerId'] is String ? data['customerId'] as String : '',
      amount: data['amount'] is num ? (data['amount'] as num).toDouble() : 0,
      type: type,
      photoUrl: data['photoUrl'] is String ? data['photoUrl'] as String : null,
      note: data['note'] is String ? data['note'] as String : null,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }
}
