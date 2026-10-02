class PaymentRecord {
  PaymentRecord({
    this.id = '',
    required this.customerId,
    required this.customerName,
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
    double? amount,
    DateTime? paymentDate,
    String? note,
    String? recordedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PaymentRecord(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        amount: amount ?? this.amount,
        paymentDate: paymentDate ?? this.paymentDate,
        note: note ?? this.note,
        recordedBy: recordedBy ?? this.recordedBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
