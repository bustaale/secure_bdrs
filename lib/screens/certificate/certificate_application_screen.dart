import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/birth_record.dart';
import '../../providers/records_provider.dart';
import '../../providers/abn_provider.dart';

class CertificateApplicationScreen extends StatefulWidget {
  final BirthRecord birthRecord;

  const CertificateApplicationScreen({
    Key? key,
    required this.birthRecord,
  }) : super(key: key);

  @override
  State<CertificateApplicationScreen> createState() => _CertificateApplicationScreenState();
}

class _CertificateApplicationScreenState extends State<CertificateApplicationScreen> {
  bool _isProcessing = false;
  final _certificateNumberController = TextEditingController();

  @override
  void dispose() {
    _certificateNumberController.dispose();
    super.dispose();
  }

  Future<void> _completeApplication() async {
    if (!_validateApplication()) return;

    // Check if payment is completed
    if (widget.birthRecord.paymentRequired && !widget.birthRecord.paymentCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete payment first'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
      final abnProvider = Provider.of<ABNProvider>(context, listen: false);

      // Check if ABN application is approved
      if (widget.birthRecord.abnApplicationId != null && widget.birthRecord.abnApplicationId!.isNotEmpty) {
        final abnApp = abnProvider.getABNApplicationById(widget.birthRecord.abnApplicationId!);
        
        // If ABN application ID exists but application not found
        if (abnApp == null) {
          throw Exception('ABN Application not found. Please ensure the ABN application is properly saved.');
        }
        
        // Automatically approve ABN if birth record is approved, payment is completed, and ABN is not yet approved
        if (abnApp.status != 'approved' && 
            widget.birthRecord.approvalStatus == 'approved' && 
            widget.birthRecord.paymentCompleted) {
          // Auto-approve ABN application
          await abnProvider.approveABNApplication(
            applicationId: abnApp.id,
            approvedBy: 'System (Auto-approved)',
            reviewNotes: 'Automatically approved - birth record approved and payment completed',
          );
        } else if (abnApp.status != 'approved') {
          // ABN is not approved and conditions for auto-approval are not met
          final statusMessage = abnApp.status == 'submitted' 
              ? 'submitted and pending approval'
              : abnApp.status == 'under_review'
                  ? 'under review'
                  : abnApp.status == 'rejected'
                      ? 'rejected'
                      : abnApp.status;
          throw Exception('ABN Application must be approved first. Current status: $statusMessage');
        }
      }

      // Update birth record
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
          paymentCompleted: widget.birthRecord.paymentCompleted,
          applicationFee: widget.birthRecord.applicationFee,
          paymentReference: widget.birthRecord.paymentReference,
        certificateApplicationCompleted: true,
        certificateApplicationDate: DateTime.now(),
      );

      // Update ABN application if exists
      if (widget.birthRecord.abnApplicationId != null) {
        await abnProvider.completeCertificateApplication(
          applicationId: widget.birthRecord.abnApplicationId!,
          certificateNumber: _certificateNumberController.text.trim().isNotEmpty
              ? _certificateNumberController.text.trim()
              : null,
        );
      }

      await recordsProvider.updateBirth(updatedRecord);

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Birth Certificate Application completed successfully'),
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
      print('Certificate Application error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing certificate application: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  bool _validateApplication() {
    // Check if all required documents are uploaded
    if (widget.birthRecord.fatherIdDocumentPath == null ||
        widget.birthRecord.fatherIdDocumentPath!.isEmpty ||
        widget.birthRecord.motherIdDocumentPath == null ||
        widget.birthRecord.motherIdDocumentPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload all required documents'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return false;
    }

    // Check if approval is completed
    if (widget.birthRecord.approvalStatus != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Record must be approved before certificate application'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Birth Certificate Application',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.purple[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[600]!, Colors.purple[800]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Birth Certificate Application',
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
              
              // Requirements Checklist
              Text(
                'Application Requirements',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildRequirementItem(
                'Documents Uploaded',
                widget.birthRecord.fatherIdDocumentPath != null &&
                    widget.birthRecord.fatherIdDocumentPath!.isNotEmpty &&
                    widget.birthRecord.motherIdDocumentPath != null &&
                    widget.birthRecord.motherIdDocumentPath!.isNotEmpty,
              ),
              _buildRequirementItem(
                'Record Approved',
                widget.birthRecord.approvalStatus == 'approved',
              ),
              _buildRequirementItem(
                'Payment Completed',
                !widget.birthRecord.paymentRequired || widget.birthRecord.paymentCompleted,
              ),
              _buildRequirementItem(
                'ABN Application Submitted',
                widget.birthRecord.abnApplicationId != null,
              ),
              const SizedBox(height: 24),
              
              // Certificate Number (Optional)
              Text(
                'Certificate Number (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _certificateNumberController,
                decoration: InputDecoration(
                  labelText: 'Certificate Number',
                  hintText: 'Auto-generated if left empty',
                  prefixIcon: Icon(Icons.verified),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _completeApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isProcessing
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Complete Application',
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
    );
  }

  Widget _buildRequirementItem(String label, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green[300]! : Colors.orange[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.cancel,
            color: isCompleted ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isCompleted ? Colors.green[900] : Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

