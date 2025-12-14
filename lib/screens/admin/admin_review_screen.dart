import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/records_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/birth_record.dart';
import '../../models/death_record.dart';
import '../../services/notification_service.dart';
import '../../services/audit_log_service.dart';
import '../birth/birth_detail_screen.dart';
import '../death/death_detail_screen.dart';
import '../document_viewer_screen.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  String _selectedFilter = 'All'; // All, Pending, Approved, Rejected
  String _selectedType = 'All'; // All, Birth, Death
  final TextEditingController _rejectionReasonController = TextEditingController();

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  List<BirthRecord> get _pendingBirths {
    final provider = Provider.of<RecordsProvider>(context, listen: false);
    var births = provider.births.where((b) => b.approvalStatus == 'pending').toList();
    return births;
  }

  List<BirthRecord> get _allBirths {
    final provider = Provider.of<RecordsProvider>(context, listen: false);
    if (_selectedFilter == 'All') return provider.births;
    return provider.births.where((b) => b.approvalStatus == _selectedFilter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Review & Approval',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<RecordsProvider>(
        builder: (context, recordsProvider, child) {
          final pendingBirths = _pendingBirths;
          final allBirths = _allBirths;
          final pendingCount = pendingBirths.length;

          return Column(
            children: [
              // Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: ['All', 'Pending', 'Approved', 'Rejected']
                            .map((filter) => DropdownMenuItem(
                                  value: filter,
                                  child: Text(filter, style: GoogleFonts.poppins()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedFilter = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: ['All', 'Birth', 'Death']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type, style: GoogleFonts.poppins()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Pending Count Banner
              if (_selectedFilter == 'Pending' || _selectedFilter == 'All')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_actions, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$pendingCount Pending Review',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Records awaiting administrator approval',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Records List
              Expanded(
                child: _selectedFilter == 'Pending'
                    ? _buildPendingList(pendingBirths)
                    : _buildAllRecordsList(allBirths),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPendingList(List<BirthRecord> pendingBirths) {
    if (pendingBirths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No pending records',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingBirths.length,
      itemBuilder: (context, index) {
        final record = pendingBirths[index];
        return _buildPendingRecordCard(record);
      },
    );
  }

  Widget _buildAllRecordsList(List<BirthRecord> allBirths) {
    if (allBirths.isEmpty) {
      return Center(
        child: Text(
          'No records found',
          style: GoogleFonts.poppins(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allBirths.length,
      itemBuilder: (context, index) {
        final record = allBirths[index];
        return _buildRecordCard(record);
      },
    );
  }

  Widget _buildPendingRecordCard(BirthRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.child_care, color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.childName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Birth Registration',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pending',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Date of Birth', DateFormat('MMM dd, yyyy').format(record.dateOfBirth)),
              _buildInfoRow('Place', record.placeOfBirth),
              _buildInfoRow('Father', record.fatherName),
              _buildInfoRow('Mother', record.motherName),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectionDialog(record),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRecord(record),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(BirthRecord record) {
    Color statusColor;
    String statusText;
    
    switch (record.approvalStatus) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.child_care,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.childName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(record.dateOfBirth),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordDetails(BirthRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BirthDetailScreen(record: record),
      ),
    );
  }

  Future<void> _approveRecord(BirthRecord record) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final admin = authProvider.user;
    final adminName = admin?.name ?? 'Administrator';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Approve Record?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to approve this birth record for ${record.childName}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Approve', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
      await recordsProvider.approveBirthRecord(
        recordId: record.id,
        approvedBy: adminName,
      );

      // Send notification to user
      // Note: In a real app, you'd get the userId from the record
      // For now, we'll skip user notification if userId is not available
      
      // Log admin action
      await AuditLogService.logAction(
        'Approved birth record',
        recordType: 'birth',
        recordId: record.id,
        metadata: {
          'childName': record.childName,
          'adminName': adminName,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Record approved successfully', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRejectionDialog(BirthRecord record) async {
    _rejectionReasonController.clear();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Record', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejecting this record:',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              decoration: InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'e.g., Missing documents, Incorrect information',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              if (_rejectionReasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, _rejectionReasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      await _rejectRecord(record, reason);
    }
  }

  Future<void> _rejectRecord(BirthRecord record, String reason) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final admin = authProvider.user;
    final adminName = admin?.name ?? 'Administrator';

    try {
      final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
      await recordsProvider.rejectBirthRecord(
        recordId: record.id,
        rejectedBy: adminName,
        rejectionReason: reason,
      );

      // Send notification to user
      // Note: In a real app, you'd get the userId from the record

      // Log admin action
      await AuditLogService.logAction(
        'Rejected birth record',
        recordType: 'birth',
        recordId: record.id,
        metadata: {
          'childName': record.childName,
          'adminName': adminName,
          'rejectionReason': reason,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Record rejected', style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {}); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

