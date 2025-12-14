import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../models/death_record.dart';
import '../../providers/records_provider.dart';
import '../../widgets/government_submission_button.dart';
import 'death_form_screen.dart';

class DeathDetailScreen extends StatelessWidget {
  final DeathRecord record;

  const DeathDetailScreen({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Death Record Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red[700],
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final DeathRecord? updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeathFormScreen(recordToEdit: record),
                ),
              );
              if (updated != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Record updated!', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.green[600],
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final pdf = await _generateDeathPdf(record);
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
                  colors: [Colors.red[700]!, Colors.orangeAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
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
                    child: Icon(Icons.person, size: 70, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.name,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Death Certificate Record",
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
                    _buildSectionHeader("Death Information", Icons.assignment_rounded),
                    const SizedBox(height: 16),

                    _buildInfoCard("Registration Number", record.registrationNumber, Icons.badge_outlined),
                    if (record.idNumber != null && record.idNumber!.isNotEmpty)
                      _buildInfoCard("ID Number", record.idNumber!, Icons.credit_card),
                    if (record.gender != null && record.gender!.isNotEmpty)
                      _buildInfoCard("Gender", record.gender!, Icons.people, color: record.gender == 'Male' ? const Color(0xFF3B82F6) : const Color(0xFFEC4899)),
                    if (record.age != null)
                      _buildInfoCard("Age", "${record.age} years old", Icons.calendar_today, color: record.age! < 18 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    _buildInfoCard("Date of Death", record.dateOfDeath.toLocal().toString().split(' ')[0], Icons.calendar_today),
                    _buildInfoCard("Place of Death", record.placeOfDeath, Icons.location_on),
                    if (record.hospital != null && record.hospital!.isNotEmpty)
                      _buildInfoCard("Hospital", record.hospital!, Icons.local_hospital),
                    if (record.cause.isNotEmpty)
                      _buildInfoCard("Cause of Death", record.cause, Icons.medical_services),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Family Information", Icons.family_restroom),
                    const SizedBox(height: 16),

                    if (record.familyName != null && record.familyName!.isNotEmpty)
                      _buildInfoCard("Family Name", record.familyName!, Icons.person),
                    if (record.familyRelation != null && record.familyRelation!.isNotEmpty)
                      _buildInfoCard("Relation", record.familyRelation!, Icons.group),
                    if (record.familyPhone != null && record.familyPhone!.isNotEmpty)
                      _buildInfoCard("Phone Number", record.familyPhone!, Icons.phone),

                    const SizedBox(height: 40),

                    // Government Submission Button
                    GovernmentSubmissionButton(
                      deathRecord: record,
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

                    // Print PDF and Delete Buttons Section
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final pdf = await _generateDeathPdf(record);
                              await Printing.layoutPdf(onLayout: (_) => pdf.save());
                            },
                            icon: const Icon(Icons.print, color: Colors.white),
                            label: Text(
                              'Print PDF',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showDeleteDialog(context),
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[900],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.red[700], size: 20),
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

  Widget _buildInfoCard(String label, String value, IconData icon, {Color? color}) {
    final displayColor = color ?? Colors.red[700]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: displayColor.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: displayColor.withOpacity(0.05),
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
              color: displayColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: displayColor, size: 22),
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
  Future<pw.Document> _generateDeathPdf(DeathRecord record) async {
    final pdf = pw.Document();

    // Generate shorter certificate number (last 8 digits of timestamp)
    final String shortCertNum = "DR${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    final String issueDate = DateTime.now().toLocal().toString().split(' ')[0];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.red700, width: 4),
            ),
            child: pw.Container(
              margin: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.red300, width: 2),
              ),
              child: pw.Container(
                margin: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.red700, width: 1),
                ),
                padding: const pw.EdgeInsets.all(25),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("Republic of Kenya", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text("Ministry of Health – Civil Registration Department", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.SizedBox(height: 10),
                pw.Text("DEATH CERTIFICATE", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                pw.Container(height: 1.5, width: 120, color: PdfColors.red700),
                pw.SizedBox(height: 10),

                // Certificate Number & Issue Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Certificate No: $shortCertNum", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                    pw.Text("Date: $issueDate", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 25),

                // Death Info
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfInfo("Name:", record.name),
                      if (record.idNumber != null && record.idNumber!.isNotEmpty)
                        _buildPdfInfo("ID Number:", record.idNumber!),
                      if (record.gender != null && record.gender!.isNotEmpty)
                        _buildPdfInfo("Gender:", record.gender!),
                      if (record.age != null)
                        _buildPdfInfo("Age:", "${record.age} years old"),
                      _buildPdfInfo("Registration #:", record.registrationNumber),
                      _buildPdfInfo("Date of Death:", record.dateOfDeath.toLocal().toString().split(' ')[0]),
                      _buildPdfInfo("Place of Death:", record.placeOfDeath),
                      if (record.hospital != null && record.hospital!.isNotEmpty)
                        _buildPdfInfo("Hospital:", record.hospital!),
                      if (record.cause.isNotEmpty)
                        _buildPdfInfo("Cause of Death:", record.cause),
                      if (record.familyName != null && record.familyName!.isNotEmpty)
                        _buildPdfInfo("Next of Kin:", record.familyName!),
                      if (record.familyRelation != null && record.familyRelation!.isNotEmpty)
                        _buildPdfInfo("Relation:", record.familyRelation!),
                      if (record.familyPhone != null && record.familyPhone!.isNotEmpty)
                        _buildPdfInfo("Contact:", record.familyPhone!),
                    ],
                  ),
                ),

                pw.SizedBox(height: 40),
                // Signature + Official Seal + QR Code
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Registrar of Deaths", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
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
                            border: pw.Border.all(color: PdfColors.red700, width: 3),
                          ),
                          child: pw.Center(
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text("OFFICIAL",
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                                pw.SizedBox(height: 2),
                                pw.Container(
                                  width: 50,
                                  height: 1,
                                  color: PdfColors.red700,
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text("SEAL",
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
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
            child: pw.Text(label,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: 12, color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete Death Record',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this death record? This action cannot be undone.',
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
                      .deleteDeath(record.id ?? '');
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Death record deleted successfully',
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
                backgroundColor: Colors.red[900],
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
}
