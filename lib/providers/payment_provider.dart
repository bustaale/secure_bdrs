import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment.dart';

class PaymentProvider extends ChangeNotifier {
  final List<Payment> _payments = [];
  bool _isLoading = false;
  String? _error;
  bool _useFirebase = false;

  // Default fees
  static const double defaultApplicationFee = 500.0; // KES
  static const double defaultCertificateFee = 1000.0; // KES
  static const double defaultLateRegistrationFee = 2000.0; // KES

  List<Payment> get payments => List.unmodifiable(_payments);
  List<Payment> get completedPayments => 
      _payments.where((p) => p.status == 'completed').toList();
  List<Payment> get pendingPayments => 
      _payments.where((p) => p.status == 'pending' || p.status == 'processing').toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  PaymentProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _loadFromLocal();
    } catch (e) {
      print('Error initializing Payment Provider: $e');
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentsJson = prefs.getString('payments') ?? '[]';
      final paymentsList = json.decode(paymentsJson) as List<dynamic>;
      _payments.clear();
      _payments.addAll(
        paymentsList.map((jsonItem) {
          if (jsonItem is Map<String, dynamic>) {
            return Payment.fromMap(jsonItem);
          }
          return Payment.fromMap(Map<String, dynamic>.from(jsonItem as Map));
        }).toList(),
      );
      notifyListeners();
    } catch (e) {
      print('Error loading payments from local storage: $e');
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentsJson = json.encode(
        _payments.map((payment) => payment.toMap()).toList(),
      );
      await prefs.setString('payments', paymentsJson);
    } catch (e) {
      print('Error saving payments to local storage: $e');
    }
  }

  // Create Payment
  Future<String> createPayment({
    required String recordId,
    required String recordType,
    String? abnApplicationId,
    required double amount,
    required String paymentType,
    required String paymentMethod,
    required String payerName,
    required String payerPhone,
    String? payerEmail,
    String? payerIdNumber,
    String? description,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final payment = Payment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recordId: recordId,
        recordType: recordType,
        abnApplicationId: abnApplicationId,
        amount: amount,
        currency: 'KES',
        paymentType: paymentType,
        paymentMethod: paymentMethod,
        status: 'pending',
        payerName: payerName,
        payerPhone: payerPhone,
        payerEmail: payerEmail,
        payerIdNumber: payerIdNumber,
        description: description ?? 'Payment for $paymentType',
        paymentDate: DateTime.now(),
      );

      _payments.add(payment);
      await _saveToLocal();
      
      // Try to save to Firebase if available
      try {
        // TODO: Implement Firebase save
      } catch (e) {
        print('Firebase save failed: $e');
      }

      _isLoading = false;
      notifyListeners();
      return payment.id;
    } catch (e) {
      _error = 'Error creating payment: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Process Payment (M-Pesa, Bank, etc.)
  Future<void> processPayment({
    required String paymentId,
    required String transactionReference,
    String? mpesaCode,
    String? receiptNumber,
    String? processedBy,
  }) async {
    try {
      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index == -1) return;

      final existing = _payments[index];
      final updated = existing.copyWith(
        status: 'completed',
        transactionReference: transactionReference,
        mpesaCode: mpesaCode,
        receiptNumber: receiptNumber,
        processedDate: DateTime.now(),
        processedBy: processedBy,
      );

      _payments[index] = updated;
      await _saveToLocal();
      notifyListeners();
    } catch (e) {
      _error = 'Error processing payment: $e';
      notifyListeners();
    }
  }

  // Mark Payment as Failed
  Future<void> markPaymentFailed({
    required String paymentId,
    required String failureReason,
  }) async {
    try {
      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index == -1) return;

      final existing = _payments[index];
      final updated = existing.copyWith(
        status: 'failed',
        failureReason: failureReason,
      );

      _payments[index] = updated;
      await _saveToLocal();
      notifyListeners();
    } catch (e) {
      _error = 'Error marking payment as failed: $e';
      notifyListeners();
    }
  }

  // Get Payment by ID
  Payment? getPaymentById(String id) {
    try {
      return _payments.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get Payments by Record ID
  List<Payment> getPaymentsByRecordId(String recordId) {
    return _payments.where((p) => p.recordId == recordId).toList();
  }

  // Get Total Revenue
  double getTotalRevenue() {
    return completedPayments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  // Get Revenue by Payment Type
  double getRevenueByType(String paymentType) {
    return completedPayments
        .where((p) => p.paymentType == paymentType)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }
}

