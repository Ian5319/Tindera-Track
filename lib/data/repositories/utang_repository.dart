import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer.dart';
import '../models/utang_transaction.dart';

class UtangRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customers =>
      _firestore.collection('customers');

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('utang_transactions');

  Future<List<Customer>> getCustomers() async {
    final snapshot = await _customers.get();

    final customers = snapshot.docs
        .map(_customerFromFirestore)
        .toList();

    customers.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return customers;
  }

  Future<Customer?> getCustomer(String id) async {
    final doc = await _customers.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return _customerFromFirestore(doc);
  }

  // NEW: Create a customer manually.
  Future<Customer> createCustomer({
    required String name,
    String phone = '',
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('A customer must have a name.');
    }

    final id =
        'c${DateTime.now().microsecondsSinceEpoch}';

    final customer = Customer(
      id: id,
      name: normalizedName,
      phone: phone.trim(),
      balance: 0,
      createdAt: DateTime.now(),
    );

    await _customers.doc(id).set({
      'id': customer.id,
      'name': customer.name,
      'phone': customer.phone,
      'balance': customer.balance,
      'createdAt': Timestamp.fromDate(
        customer.createdAt,
      ),
    });

    return customer;
  }

  Future<List<UtangTransaction>> getTransactionsFor(
    String customerId,
  ) async {
    final snapshot = await _transactions
        .where(
          'customerId',
          isEqualTo: customerId,
        )
        .get();

    final transactions = snapshot.docs
        .map(_transactionFromFirestore)
        .toList();

    transactions.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return transactions;
  }

  Future<List<UtangTransaction>> getAllTransactions() async {
    final snapshot = await _transactions.get();
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
        transaction.amount <= 0) {
      throw ArgumentError('Transaction values are outside the allowed range.');
    }

    final customer = await _customers.doc(transaction.customerId).get();
    if (!customer.exists) {
      throw ArgumentError('The selected customer does not exist.');
    }

    if (transaction.type == UtangType.payment) {
      final balance = await currentBalance(transaction.customerId);
      if (transaction.amount > balance) {
        throw ArgumentError('Payment cannot be greater than the current balance.');
      }
    }

    await _transactions.doc(transaction.id).set({
      'id': transaction.id,
      'customerId': transaction.customerId,
      'amount': transaction.amount,
      'type': transaction.type.name,
      'photoUrl': transaction.photoUrl,
      'note': transaction.note,
      'createdAt': Timestamp.fromDate(
        transaction.createdAt,
      ),
    });

    await recalculate();
  }

  Future<void> recalculate() async {
    final customerSnapshot =
        await _customers.get();

    for (final customerDoc in customerSnapshot.docs) {
      final customerId = customerDoc.id;

      final transactionSnapshot = await _transactions
          .where(
            'customerId',
            isEqualTo: customerId,
          )
          .get();

      double balance = 0;

      for (final transactionDoc
          in transactionSnapshot.docs) {
        final data = transactionDoc.data();

        final amount =
            (data['amount'] as num?)?.toDouble() ?? 0;

        final type =
            data['type'] as String? ?? 'credit';

        if (type == UtangType.credit.name) {
          balance += amount;
        } else if (type == UtangType.payment.name) {
          balance -= amount;
        }
      }

      if (balance < 0) {
        balance = 0;
      }

      await _customers.doc(customerId).update({
        'balance': balance,
      });
    }
  }

  Future<double> currentBalance(
    String customerId,
  ) async {
    final transactions =
        await getTransactionsFor(customerId);

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
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      balance:
          (data['balance'] as num?)?.toDouble() ?? 0,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.now(),
    );
  }

  UtangTransaction _transactionFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final typeString =
        data['type'] as String? ?? 'credit';

    final type =
        typeString == UtangType.payment.name
            ? UtangType.payment
            : UtangType.credit;

    final createdAt = data['createdAt'];

    return UtangTransaction(
      id: doc.id,
      customerId:
          data['customerId'] as String? ?? '',
      amount:
          (data['amount'] as num?)?.toDouble() ?? 0,
      type: type,
      photoUrl: data['photoUrl'] as String?,
      note: data['note'] as String?,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.now(),
    );
  }
}
