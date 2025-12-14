import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/birth_record.dart';
import '../../providers/records_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/government_submission_button.dart';
import '../../screens/document_viewer_screen.dart';
import '../../screens/abn/abn_application_screen.dart';
import '../../screens/payment/payment_screen.dart';
import '../../screens/certificate/certificate_application_screen.dart';
import '../../providers/abn_provider.dart';
import '../../providers/payment_provider.dart';
import 'birth_form_screen.dart';

class BirthDetailScreen extends StatelessWidget {
  final BirthRecord record;

  const BirthDetailScreen({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Birth Record Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BirthFormScreen(recordToEdit: record),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final pdf = await _generateBirthPdf(record);
              await Printing.layoutPdf(onLayout: (_) => pdf.save());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.lightBlueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 60,
                    child: Icon(Icons.child_care, size: 70, color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.childName,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Birth Certificate Record",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Container(
              margin: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Child Information", Icons.child_care),
                    const SizedBox(height: 16),

                    _buildInfoCard("Full Name", record.childName, Icons.person),
                    _buildInfoCard(
                      "Date of Birth",
                      record.dateOfBirth != null
                          ? record.dateOfBirth!.toLocal().toString().split(' ')[0]
                          : "Not provided",
                      Icons.calendar_today,
                    ),
                    _buildInfoCard("Place of Birth", record.placeOfBirth, Icons.location_on),
                    _buildInfoCard("Gender",
                        record.gender.isNotEmpty ? record.gender : "Not provided", Icons.wc),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Father Information", Icons.male),
                    const SizedBox(height: 16),
                    _buildInfoCard("Full Name", record.fatherName, Icons.person),
                    _buildInfoCard("National ID",
                        record.fatherNationalId.isNotEmpty ? record.fatherNationalId : "Not provided", Icons.credit_card),
                    _buildInfoCard("Phone",
                        record.fatherPhone.isNotEmpty ? record.fatherPhone : "Not provided", Icons.phone),
                    _buildInfoCard("Email",
                        record.fatherEmail.isNotEmpty ? record.fatherEmail : "Not provided", Icons.email),
                    _buildInfoCard("Citizenship",
                        record.fatherCitizenship.isNotEmpty ? record.fatherCitizenship : "Not provided", Icons.flag),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Mother Information", Icons.female),
                    const SizedBox(height: 16),
                    _buildInfoCard("Full Name", record.motherName, Icons.person),
                    _buildInfoCard("National ID",
                        record.motherNationalId.isNotEmpty ? record.motherNationalId : "Not provided", Icons.credit_card),
                    _buildInfoCard("Phone",
                        record.motherPhone.isNotEmpty ? record.motherPhone : "Not provided", Icons.phone),
                    _buildInfoCard("Email",
                        record.motherEmail.isNotEmpty ? record.motherEmail : "Not provided", Icons.email),
                    _buildInfoCard("Citizenship",
                        record.motherCitizenship.isNotEmpty ? record.motherCitizenship : "Not provided", Icons.flag),

                    const SizedBox(height: 32),
                    
                    // Document Uploads Section
                    _buildSectionHeader("Uploaded Documents", Icons.upload_file),
                    const SizedBox(height: 16),
                    if (record.fatherIdDocumentPath != null && record.fatherIdDocumentPath!.isNotEmpty)
                      _buildDocumentCard(
                        context: context,
                        label: "Father's ID/LP Document",
                        filePath: record.fatherIdDocumentPath!,
                      ),
                    if (record.motherIdDocumentPath != null && record.motherIdDocumentPath!.isNotEmpty)
                      _buildDocumentCard(
                        context: context,
                        label: "Mother's ID/LP Document",
                        filePath: record.motherIdDocumentPath!,
                      ),
                    if ((record.fatherIdDocumentPath == null || record.fatherIdDocumentPath!.isEmpty) &&
                        (record.motherIdDocumentPath == null || record.motherIdDocumentPath!.isEmpty))
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "No documents uploaded yet",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),
                    
                    // Approval Status Section
                    _buildApprovalStatusSection(context, record),

                    const SizedBox(height: 40),

                    // ABN Application Section
                    _buildABNSection(context, record),
                    const SizedBox(height: 16),

                    // Payment Section
                    _buildPaymentSection(context, record),
                    const SizedBox(height: 16),

                    // Certificate Application Section
                    _buildCertificateApplicationSection(context, record),
                    const SizedBox(height: 16),

                    // Government Submission Button
                    GovernmentSubmissionButton(
                      birthRecord: record,
                      onSuccess: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Record submitted to government successfully',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.green[600],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Delete Button Section
                    ElevatedButton.icon(
                      onPressed: () => _showDeleteDialog(context),
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: Text(
                        'Delete Record',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete Birth Record',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this birth record? This action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await Provider.of<RecordsProvider>(context, listen: false)
                      .deleteBirth(record.id ?? '');
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Birth record deleted successfully',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.green[600],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error deleting record: $e',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue[700], size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue[700], size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[900],
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== PDF Generator =====================
  Future<pw.Document> _generateBirthPdf(BirthRecord record) async {
    final pdf = pw.Document();

    final String certNumber = record.id ?? "BCRS-${DateTime.now().millisecondsSinceEpoch}";
    final String shortCertNum = "BR${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    final String issueDate = DateTime.now().toLocal().toString().split(' ')[0];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue700, width: 4),
            ),
            child: pw.Container(
              margin: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue300, width: 2),
              ),
              child: pw.Container(
                margin: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue700, width: 1),
                ),
                padding: const pw.EdgeInsets.all(25),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                pw.Text("Republic of Kenya", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text("Ministry of Health – Civil Registration Department", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.SizedBox(height: 10),
                pw.Text("BIRTH CERTIFICATE", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.Container(height: 1.5, width: 120, color: PdfColors.blue700),
                pw.SizedBox(height: 10),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Certificate No: $shortCertNum", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.Text("Date: $issueDate", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 25),

                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfInfo("Child Name:", record.childName),
                      _buildPdfInfo("Date of Birth:",
                          record.dateOfBirth != null ? record.dateOfBirth!.toLocal().toString().split(' ')[0] : "Not provided"),
                      _buildPdfInfo("Place of Birth:", record.placeOfBirth),
                      _buildPdfInfo("Gender:", record.gender),
                      pw.SizedBox(height: 10),
                      _buildPdfInfo("Father Name:", record.fatherName),
                      _buildPdfInfo("Father ID:", record.fatherNationalId.isNotEmpty ? record.fatherNationalId : "Not provided"),
                      _buildPdfInfo("Mother Name:", record.motherName),
                      _buildPdfInfo("Mother ID:", record.motherNationalId.isNotEmpty ? record.motherNationalId : "Not provided"),
                    ],
                  ),
                ),

                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Registrar of Births", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 25),
                        pw.Container(width: 180, height: 1, color: PdfColors.grey700),
                        pw.SizedBox(height: 5),
                        pw.Text("Authorized Signature", style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                      ],
                    ),
                    // Official Seal and QR Code
                    pw.Column(
                      children: [
                        // Official Seal - centered and larger
                        pw.Container(
                          width: 110,
                          height: 110,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(color: PdfColors.blue700, width: 3),
                          ),
                          child: pw.Center(
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text("OFFICIAL",
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                                pw.SizedBox(height: 2),
                                pw.Container(
                                  width: 50,
                                  height: 1,
                                  color: PdfColors.blue700,
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text("SEAL",
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        // QR Code - Certificate Verification
                        pw.BarcodeWidget(
                          data: "BDRS-CERT:$shortCertNum",
                          barcode: pw.Barcode.qrCode(),
                          width: 70,
                          height: 70,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text("Scan to Verify Certificate", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                        pw.SizedBox(height: 2),
                        pw.Text("ID: $shortCertNum", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text("Generated by Secure BDRS System",
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ),
              ],
            ),
          ),
          ),
          );
        },
      ),
    );
    return pdf;
  }

  pw.Widget _buildPdfInfo(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: 12, color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required BuildContext context,
    required String label,
    required String filePath,
  }) {
    final file = File(filePath);
    final exists = file.existsSync();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.description, color: Colors.green[700], size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exists ? "Document available ✓" : "File not found",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: exists ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
          if (exists)
            IconButton(
              icon: Icon(Icons.visibility, color: Colors.blue[600]),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentViewerScreen(
                      filePath: filePath,
                      documentName: label,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildApprovalStatusSection(BuildContext context, BirthRecord record) {
    final status = record.approvalStatus;
    final isPending = status == 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isApproved) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Approved';
    } else if (isRejected) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Rejected';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Pending Approval';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Approval Status",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (record.approvedBy != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow("Reviewed By", record.approvedBy!),
          ],
          if (record.approvedAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              "Date",
              record.approvedAt!.toLocal().toString().split(' ')[0],
            ),
          ],
          if (isRejected && record.rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Rejection Reason:",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.rejectionReason!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(context, record, true),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: Text(
                      'Approve',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(context, record, false),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  void _showApprovalDialog(BuildContext context, BirthRecord record, bool isApproval) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isApproval ? 'Approve Birth Record' : 'Reject Birth Record',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isApproval
                    ? 'Are you sure you want to approve this birth record?'
                    : 'Please provide a reason for rejection:',
                style: GoogleFonts.poppins(),
              ),
              if (!isApproval) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Rejection Reason',
                    hintText: 'Enter reason for rejection...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                  style: GoogleFonts.poppins(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!isApproval && reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Please provide a rejection reason'),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();
                
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final user = authProvider.user;
                final approverName = user?.name?.isNotEmpty == true
                    ? user!.name!
                    : user?.email ?? 'Administrator';

                final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
                
                try {
                  if (isApproval) {
                    await recordsProvider.approveBirthRecord(
                      recordId: record.id,
                      approvedBy: approverName,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Birth record approved successfully'),
                          backgroundColor: Colors.green[600],
                        ),
                      );
                    }
                  } else {
                    await recordsProvider.rejectBirthRecord(
                      recordId: record.id,
                      rejectedBy: approverName,
                      rejectionReason: reasonController.text.trim(),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Birth record rejected'),
                          backgroundColor: Colors.orange[600],
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isApproval ? Colors.green[600] : Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isApproval ? 'Approve' : 'Reject',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildABNSection(BuildContext context, BirthRecord record) {
    return Consumer<ABNProvider>(
      builder: (context, abnProvider, child) {
        final abnApp = record.abnApplicationId != null
            ? abnProvider.getABNApplicationById(record.abnApplicationId!)
            : null;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.description, color: Colors.blue[700], size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ABN Application',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        if (abnApp != null)
                          Text(
                            'Status: ${abnApp.status.toUpperCase()}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (abnApp == null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ABNApplicationScreen(birthRecord: record),
                        ),
                      );
                      if (result == true && context.mounted) {
                        // Refresh the screen by popping and getting updated record
                        final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
                        final updatedRecord = recordsProvider.findBirthById(record.id);
                        if (updatedRecord != null) {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BirthDetailScreen(record: updatedRecord),
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.add_circle_outline),
                    label: Text('Create ABN Application'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    _buildInfoRow('Application Number', abnApp.applicationNumber),
                    _buildInfoRow('Applicant', abnApp.applicantName),
                    _buildInfoRow('Relationship', abnApp.relationshipToChild),
                    if (abnApp.applicationFee != null)
                      _buildInfoRow('Fee', 'KES ${abnApp.applicationFee!.toStringAsFixed(2)}'),
                    if (abnApp.paymentCompleted)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Payment Completed',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentSection(BuildContext context, BirthRecord record) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        final payments = paymentProvider.getPaymentsByRecordId(record.id);
        final hasPendingPayment = payments.any((p) => p.status == 'pending' || p.status == 'processing');
        final hasCompletedPayment = payments.any((p) => p.status == 'completed');

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.payment, color: Colors.green[700], size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payment',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (record.paymentRequired && !record.paymentCompleted && !hasCompletedPayment)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            birthRecord: record,
                            paymentType: 'application_fee',
                          ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        // Refresh the screen by popping and getting updated record
                        final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
                        final updatedRecord = recordsProvider.findBirthById(record.id);
                        if (updatedRecord != null) {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BirthDetailScreen(record: updatedRecord),
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.payment),
                    label: Text('Process Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else if (hasCompletedPayment || record.paymentCompleted)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Completed',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                            if (record.paymentReference != null)
                              Text(
                                'Ref: ${record.paymentReference}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCertificateApplicationSection(BuildContext context, BirthRecord record) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.verified, color: Colors.purple[700], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Birth Certificate Application',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!record.certificateApplicationCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CertificateApplicationScreen(birthRecord: record),
                    ),
                  );
                  if (result == true && context.mounted) {
                    // Refresh the screen by getting updated record from provider
                    final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
                    final updatedRecord = recordsProvider.findBirthById(record.id);
                    if (updatedRecord != null && context.mounted) {
                      // Use Future.microtask to ensure navigation happens after current execution
                      Future.microtask(() {
                        if (context.mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                          // Use another microtask for the replacement
                          Future.microtask(() {
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BirthDetailScreen(record: updatedRecord),
                                ),
                              );
                            }
                          });
                        }
                      });
                    } else if (context.mounted && Navigator.canPop(context)) {
                      // If record not found, just pop back
                      Future.microtask(() {
                        if (context.mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      });
                    }
                  }
                },
                icon: Icon(Icons.assignment_turned_in),
                label: Text('Complete Certificate Application'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.purple[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Application Completed',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple[700],
                          ),
                        ),
                        if (record.certificateApplicationDate != null)
                          Text(
                            'Date: ${record.certificateApplicationDate!.toLocal().toString().split(' ')[0]}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.purple[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
