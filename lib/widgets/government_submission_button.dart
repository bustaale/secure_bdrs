import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/government_integration_service.dart';
import '../models/birth_record.dart';
import '../models/death_record.dart';
import '../providers/auth_provider.dart';

/// Government Submission Button Widget
/// Allows users with appropriate permissions to submit records to government
class GovernmentSubmissionButton extends StatelessWidget {
  final BirthRecord? birthRecord;
  final DeathRecord? deathRecord;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const GovernmentSubmissionButton({
    super.key,
    this.birthRecord,
    this.deathRecord,
    this.onSuccess,
    this.onError,
  }) : assert(birthRecord != null || deathRecord != null, 'Either birth or death record must be provided');

  Future<void> _submitToGovernment(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) {
      _showError(context, 'You must be logged in to submit records');
      return;
    }

    // Check if user has permission
    if (!_hasPermission(user.role)) {
      _showError(context, 'You do not have permission to submit records to government');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Submit to Government',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to submit this record to the government system? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
            ),
            child: Text('Submit', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Submitting to government...',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      GovernmentSubmissionResult result;
      
      if (birthRecord != null) {
        result = await GovernmentIntegrationService.submitBirthRecord(
          birthRecord!,
          user.id,
          user.role,
        );
      } else {
        result = await GovernmentIntegrationService.submitDeathRecord(
          deathRecord!,
          user.id,
          user.role,
        );
      }

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (result.success) {
        _showSuccess(context, result);
        onSuccess?.call();
      } else {
        _showError(context, result.message, result.errors);
        onError?.call();
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      _showError(context, 'Error submitting to government: $e');
      onError?.call();
    }
  }

  bool _hasPermission(String role) {
    return role == 'admin' || role == 'registrar';
  }

  void _showSuccess(BuildContext context, GovernmentSubmissionResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 8),
            Text(
              'Success',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.green[600],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: GoogleFonts.poppins(),
            ),
            if (result.governmentReference != null) ...[
              const SizedBox(height: 12),
              Text(
                'Government Reference:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              Text(
                result.governmentReference!,
                style: GoogleFonts.poppins(
                  color: Colors.blue[600],
                ).copyWith(fontFamily: 'monospace'),
              ),
            ],
            if (result.submissionId != null) ...[
              const SizedBox(height: 8),
              Text(
                'Submission ID:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              Text(
                result.submissionId!,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 12,
                ).copyWith(fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
            ),
            child: Text('OK', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message, [List<String>? errors]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600], size: 28),
            const SizedBox(width: 8),
            Text(
              'Submission Failed',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: GoogleFonts.poppins(),
            ),
            if (errors != null && errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Errors:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...errors.map((error) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: GoogleFonts.poppins(color: Colors.red[600])),
                        Expanded(
                          child: Text(
                            error,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: Text('OK', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null || !_hasPermission(user.role)) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () => _submitToGovernment(context),
      icon: const Icon(Icons.cloud_upload, size: 20),
      label: Text(
        'Submit to Government',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

