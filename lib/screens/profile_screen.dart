import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:secure_bdrs/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/records_provider.dart';
import '../providers/settings_provider.dart';
import '../services/biometric_service.dart';
import '../services/language_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/cloud_sync_settings_screen.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _biometricEnabled = false;
  bool _isLoadingBiometric = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkBiometricStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricStatus() async {
    final enabled = await BiometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return Center(child: Text(l10n.close));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              l10n.myProfile,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF3B82F6),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: [
                Tab(icon: const Icon(Icons.person), text: l10n.profile),
                Tab(icon: const Icon(Icons.analytics), text: l10n.statistics),
                Tab(icon: const Icon(Icons.settings), text: l10n.settings),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(context, user),
              _buildStatisticsTab(context),
              _buildSettingsTab(context, user),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(BuildContext context, user) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.purple[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 50,
                    color: Colors.blue[600],
                  ),
                ).animate().scale(delay: 200.ms),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        user.role.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Profile Actions
          _buildActionCard(
            icon: Icons.edit,
            title: l10n.editProfile,
            subtitle: l10n.updateYourNameAndEmail,
            color: Colors.blue,
            onTap: () => _showEditProfileDialog(context, user),
          ).animate().slideX(delay: 200.ms),
          
          const SizedBox(height: 12),
          
          _buildActionCard(
            icon: Icons.lock,
            title: l10n.changePassword,
            subtitle: l10n.updateYourAccountPassword,
            color: Colors.orange,
            onTap: () => _showChangePasswordDialog(context),
          ).animate().slideX(delay: 400.ms),

          const SizedBox(height: 12),

          _buildActionCard(
            icon: Icons.fingerprint,
            title: l10n.biometricAuthentication,
            subtitle: _biometricEnabled ? l10n.enabled : l10n.notEnabled,
            color: Colors.green,
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: (value) => _toggleBiometric(context, value),
            ),
            onTap: null,
          ).animate().slideX(delay: 600.ms),

          const SizedBox(height: 24),

          // Account Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.accountInformation,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(l10n.userID, user.id),
                const Divider(),
                _buildInfoRow(l10n.email, user.email),
                const Divider(),
                _buildInfoRow(l10n.role, user.role.toUpperCase()),
                const Divider(),
                _buildInfoRow(l10n.accountStatus, l10n.active, isActive: true),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<RecordsProvider>(
      builder: (context, recordsProvider, child) {
        final totalRecords = recordsProvider.births.length + recordsProvider.deaths.length;
        final birthCount = recordsProvider.births.length;
        final deathCount = recordsProvider.deaths.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Total Statistics Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.purple[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.totalRecords,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalRecords',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ).animate().scale(delay: 200.ms),

              const SizedBox(height: 24),

              // Birth Records Card
              _buildStatCard(
                icon: Icons.child_care,
                title: l10n.birthRecords,
                count: birthCount,
                color: Colors.blue,
              ).animate().slideX(delay: 400.ms, begin: -0.2),

              const SizedBox(height: 16),

              // Death Records Card
              _buildStatCard(
                icon: Icons.airline_seat_flat,
                title: l10n.deathRecords,
                count: deathCount,
                color: Colors.red,
              ).animate().slideX(delay: 600.ms, begin: -0.2),

              const SizedBox(height: 24),

              // Activity Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.activitySummary,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActivityItem(l10n.recordsCreated, totalRecords, Icons.add_circle),
                    const Divider(),
                    _buildActivityItem(l10n.birthRecords, birthCount, Icons.child_care),
                    const Divider(),
                    _buildActivityItem(l10n.deathRecords, deathCount, Icons.airline_seat_flat),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(BuildContext context, user) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final l10n = AppLocalizations.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
        children: [
          // App Settings
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    return _buildSettingTile(
                      icon: Icons.notifications,
                      title: l10n?.notifications ?? 'Notifications',
                      subtitle: l10n?.enablePushNotifications ?? 'Enable push notifications',
                      trailing: Switch(
                        value: settingsProvider.notificationsEnabled,
                        onChanged: (value) async {
                          await settingsProvider.setNotificationsEnabled(value);
                          Fluttertoast.showToast(
                            msg: value ? "Notifications enabled" : "Notifications disabled",
                            toastLength: Toast.LENGTH_SHORT,
                          );
                        },
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildSettingTile(
                  icon: Icons.language,
                  title: AppLocalizations.of(context)?.language ?? 'Language',
                  subtitle: _getCurrentLanguageName(context),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageDialog(context),
                ),
                const Divider(),
                _buildSettingTile(
                  icon: Icons.cloud,
                  title: 'Cloud Sync & Backup',
                  subtitle: 'Manage cloud storage and backups',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CloudSyncSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 20),

          // Security Settings
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingTile(
                  icon: Icons.fingerprint,
                  title: 'Biometric Login',
                  subtitle: _biometricEnabled ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: (value) => _toggleBiometric(context, value),
                  ),
                ),
                const Divider(),
                Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    return _buildSettingTile(
                      icon: Icons.lock_clock,
                      title: l10n?.autoLock ?? 'Auto Lock',
                      subtitle: '${l10n?.lockAppAfter5Minutes ?? "Lock app after"} ${settingsProvider.autoLockMinutes} min',
                      trailing: Switch(
                        value: settingsProvider.autoLockEnabled,
                        onChanged: (value) async {
                          await settingsProvider.setAutoLockEnabled(value);
                          Fluttertoast.showToast(
                            msg: value ? "Auto lock enabled" : "Auto lock disabled",
                            toastLength: Toast.LENGTH_SHORT,
                          );
                        },
                      ),
                      onTap: () => _showAutoLockDialog(context, settingsProvider),
                    );
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 20),

          // About Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.about ?? 'About',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingTile(
                  icon: Icons.info,
                  title: l10n?.appVersion ?? 'App Version',
                  subtitle: '1.0.0',
                  trailing: const SizedBox.shrink(),
                ),
                const Divider(),
                _buildSettingTile(
                  icon: Icons.help,
                  title: l10n?.helpSupport ?? 'Help & Support',
                  subtitle: l10n?.getHelpWithTheApp ?? 'Get help with the app',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showHelpDialog(context),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 24),

          // Logout Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[600]!, Colors.red[700]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(
                l10n?.logout ?? 'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 800.ms),
        ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
          ),
          Row(
            children: [
              if (isActive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              if (isActive) const SizedBox(width: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.green : Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(),
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[600]),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context, user) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.editProfile, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: l10n.email,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text,
                'email': emailController.text,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.save, style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      // Update profile logic here
      Fluttertoast.showToast(
        msg: l10n.profileUpdatedSuccessfully,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.changePassword, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.currentPassword,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.newPassword,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text) {
                Navigator.pop(context);
                Fluttertoast.showToast(
                  msg: l10n.passwordChangedSuccessfully,
                  toastLength: Toast.LENGTH_SHORT,
                );
              } else {
                Fluttertoast.showToast(
                  msg: l10n.passwordsDoNotMatch,
                  toastLength: Toast.LENGTH_SHORT,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.change, style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(BuildContext context, bool value) async {
    setState(() {
      _isLoadingBiometric = true;
    });

    try {
      if (value) {
        // Enable biometric - need password to save credentials
        final password = await _showPasswordDialog(context);
        if (password == null || password.isEmpty) {
          setState(() {
            _biometricEnabled = false;
            _isLoadingBiometric = false;
          });
          return;
        }

        final user = Provider.of<AuthProvider>(context, listen: false).user;
        if (user != null) {
          await BiometricService.enableBiometric(user.email, password);
          setState(() {
            _biometricEnabled = true;
          });
          final l10n = AppLocalizations.of(context);
          Fluttertoast.showToast(
            msg: l10n?.biometricAuthenticationEnabled ?? "Biometric authentication enabled",
            toastLength: Toast.LENGTH_SHORT,
          );
        }
      } else {
        await BiometricService.disableBiometric();
        setState(() {
          _biometricEnabled = false;
        });
        final l10n = AppLocalizations.of(context);
        Fluttertoast.showToast(
          msg: l10n?.biometricAuthenticationDisabled ?? "Biometric authentication disabled",
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString().replaceAll('Exception: ', '')}",
        toastLength: Toast.LENGTH_SHORT,
      );
      setState(() {
        _biometricEnabled = !value;
      });
    } finally {
      setState(() {
        _isLoadingBiometric = false;
      });
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Enable Biometric', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your password to enable biometric authentication',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Enable', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    return result;
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n?.logout ?? 'Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(l10n?.areYouSureYouWantToLogout ?? 'Are you sure you want to logout?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
              await recordsProvider.forceSave();
              await authProvider.logout();
              if (context.mounted) {
                Get.offAll(() => const LoginScreen());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n?.logout ?? 'Logout', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Help & Support', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: support@kajiado.go.ke', style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text('Phone: +254 700 000 000', style: GoogleFonts.poppins()),
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

  String _getCurrentLanguageName(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final l10n = AppLocalizations.of(context);
    
    if (languageService.isEnglish) {
      return l10n?.english ?? 'English';
    } else if (languageService.isKiswahili) {
      return l10n?.kiswahili ?? 'Kiswahili';
    } else {
      return languageService.languageName;
    }
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final l10n = AppLocalizations.of(context);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n?.language ?? 'Language',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(
                l10n?.english ?? 'English',
                style: GoogleFonts.poppins(),
              ),
              value: 'en',
              groupValue: languageService.languageCode,
              onChanged: (value) async {
                if (value != null) {
                  await languageService.setLanguage(value);
                  if (context.mounted) {
                    // Close dialog first
                    Navigator.pop(context);
                    // Wait for app to rebuild with new locale
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (context.mounted) {
                      // Get fresh context with new locale
                      final newL10n = AppLocalizations.of(context);
                      Fluttertoast.showToast(
                        msg: newL10n?.languageChanged ?? "Language changed successfully",
                        toastLength: Toast.LENGTH_SHORT,
                      );
                    }
                  }
                }
              },
            ),
            RadioListTile<String>(
              title: Text(
                l10n?.kiswahili ?? 'Kiswahili',
                style: GoogleFonts.poppins(),
              ),
              value: 'sw',
              groupValue: languageService.languageCode,
              onChanged: (value) async {
                if (value != null) {
                  await languageService.setLanguage(value);
                  if (context.mounted) {
                    // Close dialog first
                    Navigator.pop(context);
                    // Wait for app to rebuild with new locale
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (context.mounted) {
                      // Get fresh context with new locale
                      final newL10n = AppLocalizations.of(context);
                      Fluttertoast.showToast(
                        msg: newL10n?.languageChanged ?? "Language changed successfully",
                        toastLength: Toast.LENGTH_SHORT,
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n?.cancel ?? 'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAutoLockDialog(BuildContext context, SettingsProvider settingsProvider) async {
    final l10n = AppLocalizations.of(context);
    int selectedMinutes = settingsProvider.autoLockMinutes;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            l10n?.autoLock ?? 'Auto Lock',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select auto-lock time:',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              RadioListTile<int>(
                title: Text('1 minute', style: GoogleFonts.poppins()),
                value: 1,
                groupValue: selectedMinutes,
                onChanged: (value) => setState(() => selectedMinutes = value!),
              ),
              RadioListTile<int>(
                title: Text('5 minutes', style: GoogleFonts.poppins()),
                value: 5,
                groupValue: selectedMinutes,
                onChanged: (value) => setState(() => selectedMinutes = value!),
              ),
              RadioListTile<int>(
                title: Text('10 minutes', style: GoogleFonts.poppins()),
                value: 10,
                groupValue: selectedMinutes,
                onChanged: (value) => setState(() => selectedMinutes = value!),
              ),
              RadioListTile<int>(
                title: Text('15 minutes', style: GoogleFonts.poppins()),
                value: 15,
                groupValue: selectedMinutes,
                onChanged: (value) => setState(() => selectedMinutes = value!),
              ),
              RadioListTile<int>(
                title: Text('30 minutes', style: GoogleFonts.poppins()),
                value: 30,
                groupValue: selectedMinutes,
                onChanged: (value) => setState(() => selectedMinutes = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n?.cancel ?? 'Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () async {
                await settingsProvider.setAutoLockMinutes(selectedMinutes);
                Navigator.pop(context);
                Fluttertoast.showToast(
                  msg: "Auto lock time set to $selectedMinutes minutes",
                  toastLength: Toast.LENGTH_SHORT,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(l10n?.save ?? 'Save', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

