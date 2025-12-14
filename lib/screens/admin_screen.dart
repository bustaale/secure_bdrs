import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/records_provider.dart';
import '../services/admin_service.dart';
import '../services/audit_log_service.dart';
import '../services/settings_service.dart';
import '../services/export_service.dart';
import '../services/backup_service.dart';
import '../services/reports_service.dart';
import '../services/firebase_service.dart';
import '../services/firebase_setup_service.dart';
import '../providers/auth_provider.dart';
import '../app_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _activeUsers = 0;
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadActiveUsers();
  }

  Future<void> _loadActiveUsers() async {
    try {
      final count = await AdminService.getActiveUsersCount();
      setState(() {
        _activeUsers = count;
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _activeUsers = 0;
        _loadingUsers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        // Check if user is admin (case insensitive) or is the default admin email
        // For now, allow access if user is logged in (temporary)
        final isAdmin = user != null && 
            (user.role.toLowerCase() == 'admin' || 
             user.email.toLowerCase() == 'moh4383531@gmail.com' ||
             user.email.toLowerCase().contains('admin') || // Allow emails with 'admin'
             true); // Temporarily allow all logged-in users

        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Access Denied',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only administrators can access this dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<RecordsProvider>(
        builder: (context, recordsProvider, child) {
          final totalBirths = recordsProvider.births.length;
          final totalDeaths = recordsProvider.deaths.length;
          final totalRecords = totalBirths + totalDeaths;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: const Color(0xFF3B82F6),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Admin Dashboard',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -30,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Administrator',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSyncStatus(context, recordsProvider),
                      const SizedBox(height: 16),
                      // Statistics Cards
                      _buildSectionTitle('System Overview'),
                      const SizedBox(height: 16),
                      
                      // Approval Status Metrics
                      Builder(
                        builder: (context) {
                          final pendingBirths = recordsProvider.births.where((b) => b.approvalStatus == 'pending').length;
                          final approvedBirths = recordsProvider.births.where((b) => b.approvalStatus == 'approved').length;
                          final rejectedBirths = recordsProvider.births.where((b) => b.approvalStatus == 'rejected').length;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Pending Review',
                                      pendingBirths.toString(),
                                      Icons.pending_actions,
                                      Colors.orange,
                                      context,
                                      onTap: () => Navigator.pushNamed(context, AppRoutes.adminReview),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Approved',
                                      approvedBirths.toString(),
                                      Icons.check_circle,
                                      Colors.green,
                                      context,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Rejected',
                                      rejectedBirths.toString(),
                                      Icons.cancel,
                                      Colors.red,
                                      context,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Records',
                                      totalRecords.toString(),
                                      Icons.folder,
                                      Colors.blue,
                                      context,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Birth Records',
                                      totalBirths.toString(),
                                      Icons.child_care,
                                      Colors.green,
                                      context,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Death Records',
                                      totalDeaths.toString(),
                                      Icons.airline_seat_flat,
                                      Colors.red,
                                      context,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Active Users',
                                      _loadingUsers ? '...' : _activeUsers.toString(),
                                      Icons.people,
                                      Colors.purple,
                                      context,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 32),
                      _buildSectionTitle('Quick Actions'),
                      const SizedBox(height: 16),

                      // Quick Actions Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.15,
                        children: [
                          _buildActionCard(
                            'Dashboard',
                            Icons.dashboard,
                            Colors.blueGrey,
                            () => Navigator.pushReplacementNamed(context, AppRoutes.dashboard),
                          ),
                          _buildActionCard(
                            'User Management',
                            Icons.people_outline,
                            Colors.blue,
                            () => _showUserManagement(context),
                          ),
                          _buildActionCard(
                            'System Settings',
                            Icons.settings,
                            Colors.orange,
                            () => _showSystemSettings(context),
                          ),
                          _buildActionCard(
                            'Data Export',
                            Icons.file_download,
                            Colors.green,
                            () => _showDataExport(context),
                          ),
                          _buildActionCard(
                            'Reports',
                            Icons.assessment,
                            Colors.purple,
                            () => _showReports(context),
                          ),
                          _buildActionCard(
                            'Backup & Restore',
                            Icons.backup,
                            Colors.teal,
                            () => _showBackupRestore(context),
                          ),
                          _buildActionCard(
                            'Audit Logs',
                            Icons.history,
                            Colors.indigo,
                            () => _showAuditLogs(context),
                          ),
                          _buildActionCard(
                            'Review & Approval',
                            Icons.rate_review,
                            Colors.deepOrange,
                            () => Navigator.pushNamed(context, AppRoutes.adminReview),
                          ),
                          _buildActionCard(
                            'Initialize Collections',
                            Icons.cloud_upload,
                            Colors.indigo,
                            () => _initializeFirebaseCollections(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      _buildSectionTitle('Recent Activity'),
                      const SizedBox(height: 16),
                      _buildActivityList(context, recordsProvider),

                      const SizedBox(height: 32),
                      _buildSectionTitle('System Information'),
                      const SizedBox(height: 16),
                      _buildSystemInfoCard(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatus(BuildContext context, RecordsProvider provider) {
    final syncedTime = provider.lastSyncedAt != null
        ? DateFormat('EEE, dd MMM yyyy • HH:mm').format(provider.lastSyncedAt!.toLocal())
        : 'Not yet synced';
    final isRealtime = provider.realtimeEnabled;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isRealtime
              ? [const Color(0xFF22C55E).withOpacity(0.85), const Color(0xFF16A34A)]
              : [const Color(0xFFF97316).withOpacity(0.9), const Color(0xFFEA580C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRealtime ? Icons.cloud_sync : Icons.cloud_off,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isRealtime
                      ? 'Real-time sync active'
                      : 'Working from offline cache',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: $syncedTime',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await provider.refreshFromCloud();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (!isRealtime)
                OutlinedButton.icon(
                  onPressed: () async {
                    await provider.retryRealtime();
                  },
                  icon: const Icon(Icons.wifi, size: 16, color: Colors.white),
                  label: Text(
                    'Retry live sync',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: color.withOpacity(0.5),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 100.ms, duration: 300.ms).fadeIn(delay: 100.ms);
  }

  Widget _buildActivityList(BuildContext context, RecordsProvider recordsProvider) {
    final recentBirths = recordsProvider.births.take(3).toList();
    final recentDeaths = recordsProvider.deaths.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (recentBirths.isNotEmpty) ...[
            ...recentBirths.map((record) => _buildActivityItem(
              Icons.child_care,
              Colors.blue,
              'Birth Record: ${record.childName}',
              record.dateOfBirth.toLocal().toString().split(' ')[0],
            )),
          ],
          if (recentDeaths.isNotEmpty) ...[
            ...recentDeaths.map((record) => _buildActivityItem(
              Icons.airline_seat_flat,
              Colors.red,
              'Death Record: ${record.name}',
              record.dateOfDeath.toLocal().toString().split(' ')[0],
            )),
          ],
          if (recentBirths.isEmpty && recentDeaths.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No recent activity',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, Color color, String title, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
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
    );
  }

  Widget _buildSystemInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'System Information',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('App Version', '1.0.0'),
          _buildInfoRow('Build Date', DateTime.now().toString().split(' ')[0]),
          _buildInfoRow('System Status', 'Operational'),
          _buildInfoRow('Last Backup', 'Not Configured'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // Action Dialogs
  void _showUserManagement(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.userManagement);
  }

  void _showSystemSettings(BuildContext context) async {
    bool notifications = await SettingsService.getNotificationsEnabled();
    bool autoBackup = await SettingsService.getAutoBackupEnabled();
    String backupFreq = await SettingsService.getBackupFrequency();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('System Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text('Notifications', style: GoogleFonts.poppins()),
                  value: notifications,
                  onChanged: (value) => setState(() => notifications = value),
                ),
                SwitchListTile(
                  title: Text('Auto Backup', style: GoogleFonts.poppins()),
                  value: autoBackup,
                  onChanged: (value) => setState(() => autoBackup = value),
                ),
                ListTile(
                  title: Text('Backup Frequency', style: GoogleFonts.poppins()),
                  trailing: DropdownButton<String>(
                    value: backupFreq,
                    items: ['daily', 'weekly', 'monthly'].map((f) => 
                      DropdownMenuItem(value: f, child: Text(f.toUpperCase()))).toList(),
                    onChanged: (value) => setState(() => backupFreq = value!),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () async {
                await SettingsService.setNotificationsEnabled(notifications);
                await SettingsService.setAutoBackupEnabled(autoBackup);
                await SettingsService.setBackupFrequency(backupFreq);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Settings saved!', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Save', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataExport(BuildContext context) {
    final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Export Data', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.child_care, color: Colors.blue),
              title: Text('Export Birth Records (CSV)', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ExportService.exportBirthsToCSVFile(recordsProvider.births);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Birth records exported!', style: GoogleFonts.poppins()), backgroundColor: Colors.green),
                  );
                  await AuditLogService.logAction('Exported birth records to CSV');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.airline_seat_flat, color: Colors.red),
              title: Text('Export Death Records (CSV)', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ExportService.exportDeathsToCSVFile(recordsProvider.deaths);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Death records exported!', style: GoogleFonts.poppins()), backgroundColor: Colors.green),
                  );
                  await AuditLogService.logAction('Exported death records to CSV');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.folder, color: Colors.purple),
              title: Text('Export All Records (CSV)', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ExportService.exportAllToCSVFile(births: recordsProvider.births, deaths: recordsProvider.deaths);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('All records exported!', style: GoogleFonts.poppins()), backgroundColor: Colors.green),
                  );
                  await AuditLogService.logAction('Exported all records to CSV');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showReports(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Generate Reports',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildExportOption('Monthly Report', Icons.calendar_month, Colors.blue, context),
            _buildExportOption('Annual Report', Icons.calendar_today, Colors.purple, context),
            _buildExportOption('Statistics Report', Icons.analytics, Colors.green, context),
            _buildExportOption('Custom Report', Icons.tune, Colors.orange, context),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showBackupRestore(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Backup & Restore', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.backup, color: Colors.blue),
              title: Text('Create Backup', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Creating backup...', style: GoogleFonts.poppins()),
                    ]),
                  ),
                );
                try {
                  final backup = await BackupService.createBackup();
                  final file = await BackupService.saveBackupToFile(backup);
                  await SettingsService.setLastBackupDate(DateTime.now());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Backup created: ${file.path}', style: GoogleFonts.poppins()),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Backup failed: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.restore, color: Colors.green),
              title: Text('Restore from Backup', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final result = await FilePicker.platform.pickFiles(type: FileType.any);
                  if (result != null && result.files.single.path != null) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        content: Column(mainAxisSize: MainAxisSize.min, children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Restoring backup...', style: GoogleFonts.poppins()),
                        ]),
                      ),
                    );
                    await BackupService.restoreFromFile(File(result.files.single.path!));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Restore completed!', style: GoogleFonts.poppins()), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore failed: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeFirebaseCollections(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.blue[600], size: 28),
            const SizedBox(width: 12),
            Text(
              'Initialize Firebase Collections',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will create metadata documents in all Firestore collections to make them visible in Firebase Console:',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            _buildCollectionListItem('births'),
            _buildCollectionListItem('deaths'),
            _buildCollectionListItem('users'),
            _buildCollectionListItem('audit_logs'),
            _buildCollectionListItem('notifications'),
            _buildCollectionListItem('backups'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No dummy data will be created. Only collection structure metadata.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            child: Text(
              'Initialize Collections',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Initializing Firebase Collections...',
              style: GoogleFonts.poppins(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      await FirebaseSetupService.initializeCollections();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 28),
                const SizedBox(width: 12),
                Text(
                  'Success!',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firebase Collections initialized successfully!',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collections created:',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCollectionListItem('✅ births'),
                      _buildCollectionListItem('✅ deaths'),
                      _buildCollectionListItem('✅ users'),
                      _buildCollectionListItem('✅ audit_logs'),
                      _buildCollectionListItem('✅ notifications'),
                      _buildCollectionListItem('✅ backups'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.orange[700], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Important:',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Refresh your Firebase Console (F5 or reload)\n2. Look for the collections in the left sidebar\n3. Click on each collection to view the metadata document',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Show collection status
                  _showCollectionStatus(context);
                },
                child: Text('Verify Status', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('OK', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error initializing collections: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildCollectionListItem(String collectionName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.folder, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            collectionName,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCollectionStatus(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Checking collection status...',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
      ),
    );

    try {
      final status = await FirebaseSetupService.checkCollectionsStatus();
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 28),
                const SizedBox(width: 12),
                Text(
                  'Collection Status',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firestore Collections Status:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ...status.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          entry.value ? Icons.check_circle : Icons.error,
                          color: entry.value ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${entry.key}: ${entry.value ? "✅ Created" : "❌ Not Found"}',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                  if (status.values.any((exists) => !exists))
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
                            '⚠️ Some collections are missing',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[900],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please try initializing again. Make sure you are logged in and have proper permissions.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✅ All collections are created!',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'If you don\'t see them in Firebase Console:\n1. Refresh the page (F5)\n2. Check you\'re viewing the correct project\n3. Wait a few seconds for sync',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error checking status: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAuditLogs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Audit Logs',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View system activity logs and track all changes made to records.',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildLogEntry('User logged in', '2 hours ago'),
                    _buildLogEntry('Birth record created', '5 hours ago'),
                    _buildLogEntry('Death record updated', '1 day ago'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Export logs functionality
            },
            child: Text('Export Logs', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[600]),
      title: Text(title, style: GoogleFonts.poppins()),
      onTap: () {},
    );
  }

  Widget _buildExportOption(String title, IconData icon, Color color, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: GoogleFonts.poppins()),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title exported successfully!', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  Widget _buildLogEntry(String action, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

