import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRecord {
  final String id;
  final String recordId; // Birth record ID
  final String recordType; // 'birth' or 'death'
  final double amount;
  final String currency;
  final String paymentMethod; // 'mpesa', 'bank', 'cash', 'card'
  final String paymentStatus; // 'pending', 'completed', 'failed', 'refunded'
  final String? paymentReference;
  final String? transactionId;
  final DateTime paymentDate;
  final DateTime? completedAt;
  final String? paidBy;
  final String? notes;

  PaymentRecord({
    required this.id,
    required this.recordId,
    required this.recordType,
    required this.amount,
    this.currency = 'KES',
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.paymentReference,
    this.transactionId,
    required this.paymentDate,
    this.completedAt,
    this.paidBy,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recordId': recordId,
      'recordType': recordType,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentReference': paymentReference,
      'transactionId': transactionId,
      'paymentDate': paymentDate.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'paidBy': paidBy,
      'notes': notes,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return PaymentRecord(
      id: map['id'] ?? '',
      recordId: map['recordId'] ?? '',
      recordType: map['recordType'] ?? 'birth',
      amount: map['amount']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'KES',
      paymentMethod: map['paymentMethod'] ?? 'mpesa',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      paymentReference: map['paymentReference'],
      transactionId: map['transactionId'],
      paymentDate: parseTimestamp(map['paymentDate']) ?? DateTime.now(),
      completedAt: parseTimestamp(map['completedAt']),
      paidBy: map['paidBy'],
      notes: map['notes'],
    );
  }
}

