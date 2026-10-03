class PaymentRecord {
  PaymentRecord({
    this.id = '',
    required this.customerId,
    required this.customerName,
    this.utangId,
    required this.amount,
    required this.paymentDate,
    this.note,
    required this.recordedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final String customerName;
  /// The current data model has one aggregate utang balance per customer.
  /// New records use the customer id as that aggregate's utang id.
  final String? utangId;
  final double amount;
  final DateTime paymentDate;
  final String? note;
  final String recordedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentRecord copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? utangId,
    double? amount,
    DateTime? paymentDate,
    String? note,
    bool replaceNote = false,
    String? recordedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PaymentRecord(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        utangId: utangId ?? this.utangId,
        amount: amount ?? this.amount,
        paymentDate: paymentDate ?? this.paymentDate,
        note: replaceNote ? note : note ?? this.note,
        recordedBy: recordedBy ?? this.recordedBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
