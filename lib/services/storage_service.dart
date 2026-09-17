import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/product.dart';
import '../data/models/customer.dart';
import '../data/models/utang_transaction.dart';
import '../data/models/user.dart';

class StorageService {
  static late Box<Product> products;
  static late Box<Customer> customers;
  static late Box<UtangTransaction> transactions;
  static late Box<User> users;
  static late Box<dynamic> auth;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(UtangTransactionAdapter());
    Hive.registerAdapter(UserAdapter());

    products = await Hive.openBox<Product>('products');
    customers = await Hive.openBox<Customer>('customers');
    transactions = await Hive.openBox<UtangTransaction>('transactions');
    users = await Hive.openBox<User>('users');
    auth = await Hive.openBox('auth');
    await seedMockData();
  }

  static Future<void> seedMockData() async {
    if (products.isEmpty) {
      final now = DateTime.now();
      final mockProducts = <Product>[
        Product(id: 'p1', name: 'Lucky Me! Pancit Canton', price: 18, stockQuantity: 3, threshold: 5, createdAt: now.subtract(const Duration(days: 30))),
        Product(id: 'p2', name: 'Coca-Cola 1.5L', price: 78, stockQuantity: 12, threshold: 5, createdAt: now.subtract(const Duration(days: 26))),
        Product(id: 'p3', name: 'Bear Brand 33g', price: 15, stockQuantity: 4, threshold: 5, createdAt: now.subtract(const Duration(days: 24))),
        Product(id: 'p4', name: 'Safeguard Soap', price: 26, stockQuantity: 18, threshold: 6, createdAt: now.subtract(const Duration(days: 22))),
        Product(id: 'p5', name: 'Nescafé Classic 25g', price: 42, stockQuantity: 2, threshold: 4, createdAt: now.subtract(const Duration(days: 20))),
        Product(id: 'p6', name: 'Lucky Me! Beef Mami', price: 16, stockQuantity: 21, threshold: 5, createdAt: now.subtract(const Duration(days: 18))),
        Product(id: 'p7', name: 'SkyFlakes Crackers', price: 10, stockQuantity: 5, threshold: 5, createdAt: now.subtract(const Duration(days: 16))),
        Product(id: 'p8', name: 'Argentina Corned Beef 175g', price: 55, stockQuantity: 9, threshold: 3, createdAt: now.subtract(const Duration(days: 13))),
        Product(id: 'p9', name: 'Rebisco Crackers', price: 11, stockQuantity: 14, threshold: 5, createdAt: now.subtract(const Duration(days: 9))),
        Product(id: 'p10', name: 'Surf Powder Sachet', price: 9, stockQuantity: 3, threshold: 4, createdAt: now.subtract(const Duration(days: 5))),
      ];
      await products.putAll({for (final p in mockProducts) p.id: p});
    }

    if (customers.isEmpty) {
      final now = DateTime.now();
      final mockCustomers = <Customer>[
        Customer(id: 'c1', name: 'Mang Jun', phone: '09171230001', balance: 0, createdAt: now.subtract(const Duration(days: 80))),
        Customer(id: 'c2', name: 'Ate Liza', phone: '09171230002', balance: 0, createdAt: now.subtract(const Duration(days: 70))),
        Customer(id: 'c3', name: 'Kuya Ben', phone: '09171230003', balance: 0, createdAt: now.subtract(const Duration(days: 60))),
        Customer(id: 'c4', name: 'Nena', phone: '09171230004', balance: 0, createdAt: now.subtract(const Duration(days: 55))),
        Customer(id: 'c5', name: 'Toto', phone: '09171230005', balance: 0, createdAt: now.subtract(const Duration(days: 50))),
      ];
      await customers.putAll({for (final c in mockCustomers) c.id: c});

      final txs = <UtangTransaction>[
        _tx('t1', 'c1', 120, UtangType.credit, daysAgo: 6, note: 'Snacks and drinks'),
        _tx('t2', 'c1', 50, UtangType.payment, daysAgo: 4),
        _tx('t3', 'c1', 85, UtangType.credit, daysAgo: 2),
        _tx('t4', 'c2', 200, UtangType.credit, daysAgo: 7, note: 'Grocery basics'),
        _tx('t5', 'c2', 100, UtangType.payment, daysAgo: 5),
        _tx('t6', 'c2', 45, UtangType.credit, daysAgo: 1),
        _tx('t7', 'c3', 75, UtangType.credit, daysAgo: 5),
        _tx('t8', 'c3', 25, UtangType.payment, daysAgo: 3),
        _tx('t9', 'c4', 160, UtangType.credit, daysAgo: 8),
        _tx('t10', 'c4', 60, UtangType.payment, daysAgo: 2),
        _tx('t11', 'c5', 90, UtangType.credit, daysAgo: 3),
        _tx('t12', 'c5', 30, UtangType.payment, daysAgo: 1),
      ];
      await transactions.putAll({for (final t in txs) t.id: t});
      await recalculateAllBalances();
    }

    if (users.isEmpty) {
      final demo = User(id: 'u1', name: 'Ate Rosita', email: 'rosita@example.com', phone: '09171234567', storeName: 'Rosita Sari-Sari Store');
      await users.put(demo.id, demo);
      await auth.put('credential:${demo.id}', '1234');
      await auth.put('credential:${demo.phone}', '1234');
      await auth.put('credential:rosita', '1234');
    }
  }

  static UtangTransaction _tx(String id, String customerId, double amount, UtangType type, {int daysAgo = 0, String? note}) => UtangTransaction(
        id: id,
        customerId: customerId,
        amount: amount,
        type: type,
        note: note,
        createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
      );

  static Future<void> recalculateAllBalances() async {
    for (final customer in customers.values) {
      var balance = 0.0;
      for (final tx in transactions.values.where((t) => t.customerId == customer.id)) {
        balance += tx.type == UtangType.credit ? tx.amount : -tx.amount;
      }
      await customers.put(customer.id, customer.copyWith(balance: balance < 0 ? 0 : balance));
    }
  }
}
