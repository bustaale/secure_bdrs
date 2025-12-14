import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_model.dart';
import '../models/birth_record.dart';
import '../providers/records_provider.dart';
import '../providers/auth_provider.dart';

class PaymentScreen extends StatefulWidget {
  final BirthRecord record;
  final double amount;

  const PaymentScreen({
    Key? key,
    required this.record,
    required this.amount,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _transactionIdController = TextEditingController();
  String _selectedPaymentMethod = 'mpesa';
  bool _isProcessing = false;

  final Map<String, String> _paymentMethods = {
    'mpesa': 'M-Pesa',
    'bank': 'Bank Transfer',
    'cash': 'Cash',
    'card': 'Card Payment',
  };

  @override
  void dispose() {
    _referenceController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final paidBy = user?.name?.isNotEmpty == true
          ? user!.name!
          : user?.email ?? 'User';

      // Create payment record
      final paymentRecord = PaymentRecord(
        id: const Uuid().v4(),
        recordId: widget.record.id,
        recordType: 'birth',
        amount: widget.amount,
        currency: 'KES',
        paymentMethod: _selectedPaymentMethod,
        paymentStatus: 'completed',
        paymentReference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        transactionId: _transactionIdController.text.trim().isEmpty
            ? null
            : _transactionIdController.text.trim(),
        paymentDate: DateTime.now(),
        completedAt: DateTime.now(),
        paidBy: paidBy,
      );

      // Update birth record with payment information
      final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
      
      // Create updated birth record
      final updatedRecord = BirthRecord(
        id: widget.record.id,
        childName: widget.record.childName,
        gender: widget.record.gender,
        dateOfBirth: widget.record.dateOfBirth,
        placeOfBirth: widget.record.placeOfBirth,
        bornOutsideRegion: widget.record.bornOutsideRegion,
        declarationStatement: widget.record.declarationStatement,
        fatherName: widget.record.fatherName,
        fatherNationalId: widget.record.fatherNationalId,
        fatherPhone: widget.record.fatherPhone,
        fatherEmail: widget.record.fatherEmail,
        fatherCitizenship: widget.record.fatherCitizenship,
        motherName: widget.record.motherName,
        motherNationalId: widget.record.motherNationalId,
        motherPhone: widget.record.motherPhone,
        motherEmail: widget.record.motherEmail,
        motherCitizenship: widget.record.motherCitizenship,
        photoPath: widget.record.photoPath,
        registrationNumber: widget.record.registrationNumber,
        motherId: widget.record.motherId,
        fatherId: widget.record.fatherId,
        declaration: widget.record.declaration,
        imagePath: widget.record.imagePath,
        weight: widget.record.weight,
        height: widget.record.height,
        registrationDate: widget.record.registrationDate,
        registrar: widget.record.registrar,
        certificateIssued: widget.record.certificateIssued,
        certificateIssuedDate: widget.record.certificateIssuedDate,
        certificateIssuedBy: widget.record.certificateIssuedBy,
        fatherIdDocumentPath: widget.record.fatherIdDocumentPath,
        motherIdDocumentPath: widget.record.motherIdDocumentPath,
        approvalStatus: widget.record.approvalStatus,
        approvedBy: widget.record.approvedBy,
        approvedAt: widget.record.approvedAt,
        rejectionReason: widget.record.rejectionReason,
        requiredDocuments: widget.record.requiredDocuments,
        abnApplicationId: widget.record.abnApplicationId,
        paymentRequired: widget.record.paymentRequired,
        paymentCompleted: true,
        applicationFee: widget.amount,
        paymentReference: paymentRecord.paymentReference ?? paymentRecord.transactionId,
        certificateApplicationCompleted: widget.record.certificateApplicationCompleted,
        certificateApplicationDate: widget.record.certificateApplicationDate,
      );

      await recordsProvider.updateBirth(updatedRecord);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment processed successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error processing payment: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Payment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.purple[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Payment Amount',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'KES ${widget.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Birth Registration Fee',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Payment Method Selection
                Text(
                  'Payment Method',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                ..._paymentMethods.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: RadioListTile<String>(
                      title: Text(
                        entry.value,
                        style: GoogleFonts.poppins(),
                      ),
                      value: entry.key,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() => _selectedPaymentMethod = value!);
                      },
                      activeColor: Colors.blue[600],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _selectedPaymentMethod == entry.key
                              ? Colors.blue[600]!
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Payment Reference (Optional)
                if (_selectedPaymentMethod == 'mpesa' ||
                    _selectedPaymentMethod == 'bank' ||
                    _selectedPaymentMethod == 'card')
                  TextFormField(
                    controller: _referenceController,
                    decoration: InputDecoration(
                      labelText: 'Payment Reference',
                      hintText: 'Enter payment reference number',
                      prefixIcon: Icon(Icons.receipt, color: Colors.blue[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: GoogleFonts.poppins(),
                  ),

                const SizedBox(height: 16),

                // Transaction ID (Optional)
                if (_selectedPaymentMethod == 'mpesa' ||
                    _selectedPaymentMethod == 'bank' ||
                    _selectedPaymentMethod == 'card')
                  TextFormField(
                    controller: _transactionIdController,
                    decoration: InputDecoration(
                      labelText: 'Transaction ID',
                      hintText: 'Enter transaction ID',
                      prefixIcon: Icon(Icons.confirmation_number,
                          color: Colors.blue[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: GoogleFonts.poppins(),
                  ),

                const SizedBox(height: 32),

                // Process Payment Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.green[700]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Processing...',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Process Payment',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

