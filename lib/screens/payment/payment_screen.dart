import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/birth_record.dart';
import '../../models/payment.dart';
import '../../providers/payment_provider.dart';
import '../../providers/abn_provider.dart';
import '../../providers/records_provider.dart';

class PaymentScreen extends StatefulWidget {
  final BirthRecord birthRecord;
  final Payment? existingPayment;
  final String paymentType; // 'application_fee', 'certificate_fee', etc.

  const PaymentScreen({
    Key? key,
    required this.birthRecord,
    this.existingPayment,
    this.paymentType = 'application_fee',
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _payerNameController = TextEditingController();
  final _payerPhoneController = TextEditingController();
  final _payerEmailController = TextEditingController();
  final _payerIdController = TextEditingController();
  final _transactionRefController = TextEditingController();
  final _mpesaCodeController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  
  String _paymentMethod = 'mpesa';
  bool _isProcessing = false;
  double _amount = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateAmount();
    if (widget.existingPayment != null) {
      final payment = widget.existingPayment!;
      _payerNameController.text = payment.payerName;
      _payerPhoneController.text = payment.payerPhone;
      _payerEmailController.text = payment.payerEmail ?? '';
      _payerIdController.text = payment.payerIdNumber ?? '';
      _transactionRefController.text = payment.transactionReference ?? '';
      _mpesaCodeController.text = payment.mpesaCode ?? '';
      _receiptNumberController.text = payment.receiptNumber ?? '';
      _paymentMethod = payment.paymentMethod;
      _amount = payment.amount;
    } else {
      // Pre-fill with parent information
      _payerNameController.text = widget.birthRecord.fatherName;
      _payerPhoneController.text = widget.birthRecord.fatherPhone;
      _payerEmailController.text = widget.birthRecord.fatherEmail;
      _payerIdController.text = widget.birthRecord.fatherNationalId;
    }
  }

  void _calculateAmount() {
    switch (widget.paymentType) {
      case 'application_fee':
        _amount = PaymentProvider.defaultApplicationFee;
        break;
      case 'certificate_fee':
        _amount = PaymentProvider.defaultCertificateFee;
        break;
      case 'late_registration_fee':
        _amount = PaymentProvider.defaultLateRegistrationFee;
        break;
      default:
        _amount = PaymentProvider.defaultApplicationFee;
    }
  }

  @override
  void dispose() {
    _payerNameController.dispose();
    _payerPhoneController.dispose();
    _payerEmailController.dispose();
    _payerIdController.dispose();
    _transactionRefController.dispose();
    _mpesaCodeController.dispose();
    _receiptNumberController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      final abnProvider = Provider.of<ABNProvider>(context, listen: false);
      final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);

      String? paymentId;
      
      if (widget.existingPayment != null) {
        // Update existing payment
        paymentId = widget.existingPayment!.id;
        await paymentProvider.processPayment(
          paymentId: paymentId,
          transactionReference: _transactionRefController.text.trim(),
          mpesaCode: _mpesaCodeController.text.trim().isNotEmpty 
              ? _mpesaCodeController.text.trim() 
              : null,
          receiptNumber: _receiptNumberController.text.trim().isNotEmpty
              ? _receiptNumberController.text.trim()
              : null,
          processedBy: 'System',
        );
      } else {
        // Create new payment
        paymentId = await paymentProvider.createPayment(
          recordId: widget.birthRecord.id,
          recordType: 'birth',
          abnApplicationId: widget.birthRecord.abnApplicationId,
          amount: _amount,
          paymentType: widget.paymentType,
          paymentMethod: _paymentMethod,
          payerName: _payerNameController.text.trim(),
          payerPhone: _payerPhoneController.text.trim(),
          payerEmail: _payerEmailController.text.trim().isNotEmpty
              ? _payerEmailController.text.trim()
              : null,
          payerIdNumber: _payerIdController.text.trim().isNotEmpty
              ? _payerIdController.text.trim()
              : null,
        );

        // Process payment if transaction reference is provided
        if (_transactionRefController.text.trim().isNotEmpty) {
          await paymentProvider.processPayment(
            paymentId: paymentId,
            transactionReference: _transactionRefController.text.trim(),
            mpesaCode: _mpesaCodeController.text.trim().isNotEmpty 
                ? _mpesaCodeController.text.trim() 
                : null,
            receiptNumber: _receiptNumberController.text.trim().isNotEmpty
                ? _receiptNumberController.text.trim()
                : null,
            processedBy: 'System',
          );
        }
      }

      // Update ABN application payment status if applicable
      if (widget.birthRecord.abnApplicationId != null) {
        final abnApp = abnProvider.getABNApplicationById(widget.birthRecord.abnApplicationId!);
        if (abnApp != null) {
          await abnProvider.markPaymentCompleted(
            applicationId: abnApp.id,
            paymentReference: _transactionRefController.text.trim(),
          );
          
          // Automatically approve ABN application if birth record is approved and payment is completed
          if (widget.birthRecord.approvalStatus == 'approved' && 
              _transactionRefController.text.trim().isNotEmpty &&
              abnApp.status != 'approved') {
            await abnProvider.approveABNApplication(
              applicationId: abnApp.id,
              approvedBy: 'System (Auto-approved after payment)',
              reviewNotes: 'Automatically approved after payment completion and birth record approval',
            );
          }
        }
      }

      // Update birth record payment status
      final updatedRecord = BirthRecord(
        id: widget.birthRecord.id,
        childName: widget.birthRecord.childName,
          gender: widget.birthRecord.gender,
          dateOfBirth: widget.birthRecord.dateOfBirth,
          placeOfBirth: widget.birthRecord.placeOfBirth,
          bornOutsideRegion: widget.birthRecord.bornOutsideRegion,
          declarationStatement: widget.birthRecord.declarationStatement,
          fatherName: widget.birthRecord.fatherName,
          fatherNationalId: widget.birthRecord.fatherNationalId,
          fatherPhone: widget.birthRecord.fatherPhone,
          fatherEmail: widget.birthRecord.fatherEmail,
          fatherCitizenship: widget.birthRecord.fatherCitizenship,
          motherName: widget.birthRecord.motherName,
          motherNationalId: widget.birthRecord.motherNationalId,
          motherPhone: widget.birthRecord.motherPhone,
          motherEmail: widget.birthRecord.motherEmail,
          motherCitizenship: widget.birthRecord.motherCitizenship,
          photoPath: widget.birthRecord.photoPath,
          registrationNumber: widget.birthRecord.registrationNumber,
          motherId: widget.birthRecord.motherId,
          fatherId: widget.birthRecord.fatherId,
          declaration: widget.birthRecord.declaration,
          imagePath: widget.birthRecord.imagePath,
          weight: widget.birthRecord.weight,
          height: widget.birthRecord.height,
          registrationDate: widget.birthRecord.registrationDate,
          registrar: widget.birthRecord.registrar,
          certificateIssued: widget.birthRecord.certificateIssued,
          certificateIssuedDate: widget.birthRecord.certificateIssuedDate,
          certificateIssuedBy: widget.birthRecord.certificateIssuedBy,
          fatherIdDocumentPath: widget.birthRecord.fatherIdDocumentPath,
          motherIdDocumentPath: widget.birthRecord.motherIdDocumentPath,
          approvalStatus: widget.birthRecord.approvalStatus,
          approvedBy: widget.birthRecord.approvedBy,
          approvedAt: widget.birthRecord.approvedAt,
          rejectionReason: widget.birthRecord.rejectionReason,
          requiredDocuments: widget.birthRecord.requiredDocuments,
          abnApplicationId: widget.birthRecord.abnApplicationId,
          paymentRequired: widget.birthRecord.paymentRequired,
          paymentCompleted: _transactionRefController.text.trim().isNotEmpty,
          applicationFee: widget.birthRecord.applicationFee,
          paymentReference: _transactionRefController.text.trim().isNotEmpty
              ? _transactionRefController.text.trim()
              : widget.birthRecord.paymentReference,
          certificateApplicationCompleted: widget.birthRecord.certificateApplicationCompleted,
          certificateApplicationDate: widget.birthRecord.certificateApplicationDate,
        );

      await recordsProvider.updateBirth(updatedRecord);

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment processed successfully'),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
          ),
        );
        // Use microtask to ensure navigation happens after current execution completes
        Future.microtask(() {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e, stackTrace) {
      print('Payment processing error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentTypeLabel = widget.paymentType.replaceAll('_', ' ').toUpperCase();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Process Payment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green[600],
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
                // Payment Amount Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.green[800]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        paymentTypeLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'KES ${_amount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Payment Method
                Text(
                  'Payment Method',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Select Payment Method',
                    prefixIcon: Icon(Icons.payment),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    'mpesa',
                    'bank_transfer',
                    'cash',
                    'card',
                  ].map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method.replaceAll('_', ' ').toUpperCase()),
                      )).toList(),
                  onChanged: (value) => setState(() => _paymentMethod = value!),
                ),
                const SizedBox(height: 24),
                
                // Payer Information
                Text(
                  'Payer Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildTextField(
                  controller: _payerNameController,
                  label: 'Payer Name',
                  icon: Icons.person,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _payerPhoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _payerEmailController,
                  label: 'Email (Optional)',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _payerIdController,
                  label: 'ID Number (Optional)',
                  icon: Icons.credit_card,
                ),
                const SizedBox(height: 24),
                
                // Transaction Details
                Text(
                  'Transaction Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildTextField(
                  controller: _transactionRefController,
                  label: 'Transaction Reference',
                  icon: Icons.receipt,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                if (_paymentMethod == 'mpesa')
                  _buildTextField(
                    controller: _mpesaCodeController,
                    label: 'M-Pesa Code (Optional)',
                    icon: Icons.qr_code,
                  ),
                if (_paymentMethod == 'mpesa') const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _receiptNumberController,
                  label: 'Receipt Number (Optional)',
                  icon: Icons.receipt_long,
                ),
                const SizedBox(height: 32),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isProcessing
                        ? CircularProgressIndicator(color: Colors.white)
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }
}

