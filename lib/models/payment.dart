import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment Model for tracking fees and charges
class Payment {
  final String id;
  final String recordId; // Birth or Death record ID
  final String recordType; // 'birth' or 'death'
  final String? abnApplicationId; // Reference to ABN application if applicable
  
  // Payment Details
  final double amount;
  final String currency;
  final String paymentType; // 'application_fee', 'certificate_fee', 'late_registration_fee', etc.
  final String paymentMethod; // 'cash', 'mpesa', 'bank_transfer', 'card', etc.
  
  // Payment Status
  final String status; // 'pending', 'processing', 'completed', 'failed', 'refunded'
  
  // Transaction Information
  final String? transactionReference;
  final String? mpesaCode; // For M-Pesa payments
  final String? receiptNumber;
  final DateTime? paymentDate;
  final DateTime? processedDate;
  
  // Payer Information
  final String payerName;
  final String payerPhone;
  final String? payerEmail;
  final String? payerIdNumber;
  
  // Additional Information
  final String? description;
  final String? notes;
  final String? processedBy;
  final String? failureReason;
  
  Payment({
    required this.id,
    required this.recordId,
    required this.recordType,
    this.abnApplicationId,
    required this.amount,
    this.currency = 'KES',
    required this.paymentType,
    required this.paymentMethod,
    this.status = 'pending',
    this.transactionReference,
    this.mpesaCode,
    this.receiptNumber,
    this.paymentDate,
    this.processedDate,
    required this.payerName,
    required this.payerPhone,
    this.payerEmail,
    this.payerIdNumber,
    this.description,
    this.notes,
    this.processedBy,
    this.failureReason,
  });

  // Convert to Map for Firebase/Storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recordId': recordId,
      'recordType': recordType,
      'abnApplicationId': abnApplicationId,
      'amount': amount,
      'currency': currency,
      'paymentType': paymentType,
      'paymentMethod': paymentMethod,
      'status': status,
      'transactionReference': transactionReference,
      'mpesaCode': mpesaCode,
      'receiptNumber': receiptNumber,
      'paymentDate': paymentDate?.toIso8601String(),
      'processedDate': processedDate?.toIso8601String(),
      'payerName': payerName,
      'payerPhone': payerPhone,
      'payerEmail': payerEmail,
      'payerIdNumber': payerIdNumber,
      'description': description,
      'notes': notes,
      'processedBy': processedBy,
      'failureReason': failureReason,
    };
  }

  // Create from Map (Firebase/Storage)
  factory Payment.fromMap(Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return Payment(
      id: map['id'] ?? '',
      recordId: map['recordId'] ?? '',
      recordType: map['recordType'] ?? 'birth',
      abnApplicationId: map['abnApplicationId'],
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'KES',
      paymentType: map['paymentType'] ?? 'application_fee',
      paymentMethod: map['paymentMethod'] ?? 'cash',
      status: map['status'] ?? 'pending',
      transactionReference: map['transactionReference'],
      mpesaCode: map['mpesaCode'],
      receiptNumber: map['receiptNumber'],
      paymentDate: parseTimestamp(map['paymentDate']),
      processedDate: parseTimestamp(map['processedDate']),
      payerName: map['payerName'] ?? '',
      payerPhone: map['payerPhone'] ?? '',
      payerEmail: map['payerEmail'],
      payerIdNumber: map['payerIdNumber'],
      description: map['description'],
      notes: map['notes'],
      processedBy: map['processedBy'],
      failureReason: map['failureReason'],
    );
  }

  // Create a copy with updated fields
  Payment copyWith({
    String? id,
    String? recordId,
    String? recordType,
    String? abnApplicationId,
    double? amount,
    String? currency,
    String? paymentType,
    String? paymentMethod,
    String? status,
    String? transactionReference,
    String? mpesaCode,
    String? receiptNumber,
    DateTime? paymentDate,
    DateTime? processedDate,
    String? payerName,
    String? payerPhone,
    String? payerEmail,
    String? payerIdNumber,
    String? description,
    String? notes,
    String? processedBy,
    String? failureReason,
  }) {
    return Payment(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      recordType: recordType ?? this.recordType,
      abnApplicationId: abnApplicationId ?? this.abnApplicationId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionReference: transactionReference ?? this.transactionReference,
      mpesaCode: mpesaCode ?? this.mpesaCode,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      processedDate: processedDate ?? this.processedDate,
      payerName: payerName ?? this.payerName,
      payerPhone: payerPhone ?? this.payerPhone,
      payerEmail: payerEmail ?? this.payerEmail,
      payerIdNumber: payerIdNumber ?? this.payerIdNumber,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      processedBy: processedBy ?? this.processedBy,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}

