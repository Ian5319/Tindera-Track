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
    final id =
        'c${DateTime.now().microsecondsSinceEpoch}';

    final customer = Customer(
      id: id,
      name: name.trim(),
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

  Future<void> addTransaction(
    UtangTransaction transaction,
  ) async {
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
        } else {
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

    return transactions.fold<double>(
      0,
      (total, transaction) =>
          total +
          (transaction.type == UtangType.credit
              ? transaction.amount
              : -transaction.amount),
    );
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