import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/birth_record.dart';
import '../../models/abn_application.dart';
import '../../providers/abn_provider.dart';
import '../../providers/records_provider.dart';
import '../../providers/payment_provider.dart';

class ABNApplicationScreen extends StatefulWidget {
  final BirthRecord birthRecord;
  final ABNApplication? existingApplication;

  const ABNApplicationScreen({
    Key? key,
    required this.birthRecord,
    this.existingApplication,
  }) : super(key: key);

  @override
  State<ABNApplicationScreen> createState() => _ABNApplicationScreenState();
}

class _ABNApplicationScreenState extends State<ABNApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _applicantNameController = TextEditingController();
  final _applicantIdController = TextEditingController();
  final _applicantPhoneController = TextEditingController();
  final _applicantEmailController = TextEditingController();
  String _relationshipToChild = 'Father';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingApplication != null) {
      final app = widget.existingApplication!;
      _applicantNameController.text = app.applicantName;
      _applicantIdController.text = app.applicantId;
      _applicantPhoneController.text = app.applicantPhone;
      _applicantEmailController.text = app.applicantEmail;
      _relationshipToChild = app.relationshipToChild;
    } else {
      // Pre-fill with parent information
      _applicantNameController.text = widget.birthRecord.fatherName;
      _applicantIdController.text = widget.birthRecord.fatherNationalId;
      _applicantPhoneController.text = widget.birthRecord.fatherPhone;
      _applicantEmailController.text = widget.birthRecord.fatherEmail;
      _relationshipToChild = 'Father';
    }
  }

  @override
  void dispose() {
    _applicantNameController.dispose();
    _applicantIdController.dispose();
    _applicantPhoneController.dispose();
    _applicantEmailController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final abnProvider = Provider.of<ABNProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);

      // Create ABN Application
      final applicationFee = PaymentProvider.defaultApplicationFee;
      final applicationId = await abnProvider.createABNApplication(
        birthRecordId: widget.birthRecord.id,
        applicantName: _applicantNameController.text.trim(),
        applicantId: _applicantIdController.text.trim(),
        applicantPhone: _applicantPhoneController.text.trim(),
        applicantEmail: _applicantEmailController.text.trim(),
        relationshipToChild: _relationshipToChild,
        applicationFee: applicationFee,
      );

      // Create payment record
      await paymentProvider.createPayment(
        recordId: widget.birthRecord.id,
        recordType: 'birth',
        abnApplicationId: applicationId,
        amount: applicationFee,
        paymentType: 'application_fee',
        paymentMethod: 'pending',
        payerName: _applicantNameController.text.trim(),
        payerPhone: _applicantPhoneController.text.trim(),
        payerEmail: _applicantEmailController.text.trim(),
        payerIdNumber: _applicantIdController.text.trim(),
        description: 'ABN Application Fee',
      );

      // Update birth record with ABN application ID
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
          abnApplicationId: applicationId,
          paymentRequired: true,
          paymentCompleted: false,
          applicationFee: applicationFee,
          certificateApplicationCompleted: widget.birthRecord.certificateApplicationCompleted,
          certificateApplicationDate: widget.birthRecord.certificateApplicationDate,
        );

      await recordsProvider.updateBirth(updatedRecord);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ABN Application created successfully'),
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
      print('ABN Application error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating ABN application: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.existingApplication != null 
              ? 'Edit ABN Application' 
              : 'Create ABN Application',
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
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.purple[600]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application for Birth Notification (ABN)',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Child: ${widget.birthRecord.childName}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Applicant Information
                Text(
                  'Applicant Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _applicantNameController,
                  label: 'Applicant Full Name',
                  icon: Icons.person,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _applicantIdController,
                  label: 'Applicant ID Number',
                  icon: Icons.credit_card,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _applicantPhoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _applicantEmailController,
                  label: 'Email Address',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _relationshipToChild,
                  decoration: InputDecoration(
                    labelText: 'Relationship to Child',
                    prefixIcon: Icon(Icons.family_restroom),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Father', 'Mother', 'Guardian', 'Other']
                      .map((rel) => DropdownMenuItem(
                            value: rel,
                            child: Text(rel),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _relationshipToChild = value!),
                ),
                const SizedBox(height: 32),
                
                // Application Fee Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Application Fee',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900],
                              ),
                            ),
                            Text(
                              'KES ${PaymentProvider.defaultApplicationFee.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Submit ABN Application',
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

