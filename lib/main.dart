import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:secure_bdrs/providers/records_provider.dart';
import 'package:secure_bdrs/providers/abn_provider.dart';
import 'package:secure_bdrs/providers/payment_provider.dart';
import 'package:secure_bdrs/providers/analytics_provider.dart';
import 'package:secure_bdrs/services/biometric_service.dart';
import 'package:secure_bdrs/screens/admin_screen.dart';
import 'package:secure_bdrs/screens/auth/login_screen.dart';
import 'package:secure_bdrs/screens/birth/birth_list_screen.dart';
import 'package:secure_bdrs/screens/death/death_list_screen.dart';
import 'package:secure_bdrs/screens/status_screen.dart';
import 'package:secure_bdrs/widgets/global_search_delegate.dart';
import 'app_router.dart';
import 'firebase_options.dart'; // ✅ Add this import
import 'models/birth_record.dart';
import 'models/death_record.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/profile_screen.dart';
import 'services/language_service.dart';
import 'services/user_service.dart';
import 'services/permissions_service.dart';
import 'models/user_model.dart';
import 'package:secure_bdrs/l10n/app_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase successfully initialized.');
    } else {
      print('✅ Firebase already initialized.');
    }
  } catch (e) {
    // Check if it's a duplicate app error and ignore it
    if (e.toString().contains('duplicate-app')) {
      print('⚠️ Firebase app already exists, continuing...');
    } else {
      print('❌ Firebase initialization error: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RecordsProvider()),
        ChangeNotifierProvider(create: (_) => ABNProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider3<RecordsProvider, PaymentProvider, ABNProvider, AnalyticsProvider>(
          create: (context) => AnalyticsProvider(
            recordsProvider: context.read<RecordsProvider>(),
            paymentProvider: context.read<PaymentProvider>(),
            abnProvider: context.read<ABNProvider>(),
          ),
          update: (context, recordsProvider, paymentProvider, abnProvider, previous) =>
              previous ??
              AnalyticsProvider(
                recordsProvider: recordsProvider,
                paymentProvider: paymentProvider,
                abnProvider: abnProvider,
              ),
        ),
      ],
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, SettingsProvider>(
      builder: (context, languageService, settingsProvider, child) {
        return GetMaterialApp(
          key: ValueKey('app_${languageService.locale.languageCode}'), // Force rebuild on locale change
          debugShowCheckedModeBanner: false,
          title: 'Birth & Death Registration',
          locale: languageService.locale,
          fallbackLocale: const Locale('en'), // Fallback to English if locale not found
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('sw'), // Kiswahili
          ],
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            fontFamily: GoogleFonts.poppins().fontFamily,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              brightness: Brightness.light,
            ),
            cardTheme: const CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              color: Colors.white,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
          ),
          initialRoute: AppRoutes.login,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _showAdminDashboard = true;
  bool _checkingPermission = true;

  final List<Widget> _pages = [
    const BirthListScreen(),
    const DeathListScreen(),
    const StatusScreen(),
    const RecordsPage(),
    const CertificatePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminPermission();
  }

  Future<void> _checkAdminPermission() async {
    // Get user from AuthProvider instead of UserService
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    // Debug: Print user info
    if (user != null) {
      print('Initial check - User email: ${user.email}, role: ${user.role}');
    }
    
    // Check if user is admin (case insensitive) or is the default admin email
    // For now, show admin dashboard by default if user is logged in
    final isAdmin = user != null && 
        (user.role.toLowerCase() == 'admin' || 
         user.email.toLowerCase() == 'moh4383531@gmail.com' ||
         user.email.toLowerCase().contains('admin') || // Allow emails with 'admin'
         true); // Temporarily allow all logged-in users
    
    if (isAdmin) {
      setState(() {
        _showAdminDashboard = true;
        _checkingPermission = false;
      });
    } else {
      setState(() {
        _showAdminDashboard = false; // Show normal pages if not admin
        _checkingPermission = false;
      });
    }
  }

  void _onItemTapped(int index) => _switchToPage(index);

  void _switchToPage(int index) {
    setState(() {
      _selectedIndex = index;
      _showAdminDashboard = false;
    });
  }

  void _showAdminDashboardView() async {
    // Check permission before showing admin dashboard
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    // Debug: Print user info
    if (user != null) {
      print('User email: ${user.email}');
      print('User role: ${user.role}');
    } else {
      print('User is null');
    }
    
    // Check if user is admin (case insensitive) or is the default admin email
    // For now, allow access if user exists (temporary - can be made stricter later)
    final isAdmin = user != null && 
        (user.role.toLowerCase() == 'admin' || 
         user.email.toLowerCase() == 'moh4383531@gmail.com' ||
         user.email.toLowerCase().contains('admin') || // Allow emails with 'admin' in them
         true); // Temporarily allow all logged-in users
    
    if (isAdmin) {
      setState(() {
        _showAdminDashboard = true;
        _selectedIndex = 0;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only administrators can access this feature. Your role: ${user?.role ?? "unknown"}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Secure BDRS',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Advanced Search',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.advancedSearch);
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _showAdminDashboard
            ? const AdminScreen(key: ValueKey('admin-dashboard'))
            : IndexedStack(
                key: const ValueKey('dashboard-pages'),
                index: _selectedIndex,
                children: _pages,
              ),
      ),
      drawer: _buildNavigationDrawer(context),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF3B82F6),
          unselectedItemColor: Colors.grey[500],
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 0
                      ? const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        )
                      : null,
                  color: _selectedIndex == 0 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.child_care,
                  size: 22,
                  color: _selectedIndex == 0 ? Colors.white : Colors.grey[500],
                ),
              ),
              label: 'Birth',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 1
                      ? const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        )
                      : null,
                  color: _selectedIndex == 1 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.airline_seat_flat,
                  size: 22,
                  color: _selectedIndex == 1 ? Colors.white : Colors.grey[500],
                ),
              ),
              label: 'Death',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 2
                      ? const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        )
                      : null,
                  color: _selectedIndex == 2 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  size: 22,
                  color: _selectedIndex == 2 ? Colors.white : Colors.grey[500],
                ),
              ),
              label: 'Status',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 3
                      ? const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        )
                      : null,
                  color: _selectedIndex == 3 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history,
                  size: 22,
                  color: _selectedIndex == 3 ? Colors.white : Colors.grey[500],
                ),
              ),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 4
                      ? const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        )
                      : null,
                  color: _selectedIndex == 4 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.verified,
                  size: 22,
                  color: _selectedIndex == 4 ? Colors.white : Colors.grey[500],
                ),
              ),
              label: 'Certificates',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
          children: [
          // User Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.purple[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: Colors.blue[600],
                  ),
                ).animate().scale(delay: 200.ms),
                const SizedBox(height: 12),
                Text(
                  'Admin User',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 4),
                Text(
                  'moh4383531@gmail.com',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // Get user from AuthProvider
                final authUser = authProvider.user;
                final isAdmin = authUser != null && 
                    (authUser.role.toLowerCase() == 'admin' || 
                     authUser.email.toLowerCase() == 'moh4383531@gmail.com'); // Temporary: allow this email as admin
                
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Always show Admin Dashboard in drawer, but check permission when accessing
                    _buildDrawerItem(
                      icon: Icons.dashboard,
                      title: 'Admin Dashboard',
                      onTap: () async {
                        Navigator.pop(context);
                        // Allow access - permission check is done in _showAdminDashboardView
                        _showAdminDashboardView();
                      },
                    ),
                _buildDrawerItem(
                  icon: Icons.child_care,
                  title: 'Birth Records',
                  onTap: () {
                    Navigator.pop(context);
                    _switchToPage(0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.airline_seat_flat,
                  title: 'Death Records',
                  onTap: () {
                    Navigator.pop(context);
                    _switchToPage(1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_outlined,
                  title: 'Statistics & Status',
                  onTap: () {
                    Navigator.pop(context);
                    _switchToPage(2);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: 'All Records',
                  onTap: () {
                    Navigator.pop(context);
                    _switchToPage(3);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.verified,
                  title: 'Certificates',
                  onTap: () {
                    Navigator.pop(context);
                    _switchToPage(4);
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    _showSettingsDialog(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    _showHelpDialog(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  textColor: Colors.red[600],
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context);
                  },
                ),
              ],
            );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Secure BDRS v1.0.0\n© 2025 Kajiado County',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey[700]),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: textColor ?? Colors.grey[800],
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showProfileDialog(BuildContext context) {
    // Redirect to full profile screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  'Settings',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.notifications, color: Colors.blue[600]),
                        title: Text('Notifications', style: GoogleFonts.poppins()),
                        trailing: Switch(
                          value: settingsProvider.notificationsEnabled,
                          onChanged: (value) async {
                            await settingsProvider.setNotificationsEnabled(value);
                            setState(() {});
                          },
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.language, color: Colors.blue[600]),
                        title: Text('Language', style: GoogleFonts.poppins()),
                        trailing: Text('English', style: GoogleFonts.poppins(color: Colors.grey[600])),
                      ),
                      FutureBuilder<bool>(
                        future: BiometricService.isAvailable(),
                        builder: (context, snapshot) {
                          final isAvailable = snapshot.data ?? false;
                          if (!isAvailable) {
                            return const SizedBox.shrink();
                          }
                          return ListTile(
                            leading: Icon(Icons.fingerprint, color: Colors.green[600]),
                            title: Text('Biometric Login', style: GoogleFonts.poppins()),
                            subtitle: Text(
                              'Use fingerprint or face ID to login',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: Switch(
                              value: settingsProvider.biometricEnabled,
                              onChanged: (value) async {
                                if (value) {
                                  // Check if biometric is available
                                  final available = await BiometricService.isAvailable();
                                  if (!available) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Biometric authentication is not available on this device',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.orange[600],
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                }
                                await settingsProvider.setBiometricEnabled(value);
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Need help with the app?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.email, color: Colors.blue[600]),
              title: Text('Email Support', style: GoogleFonts.poppins()),
              subtitle: Text('support@kajiado.go.ke', style: GoogleFonts.poppins(color: Colors.grey[600])),
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Colors.blue[600]),
              title: Text('Phone Support', style: GoogleFonts.poppins()),
              subtitle: Text('+254 700 000 000', style: GoogleFonts.poppins(color: Colors.grey[600])),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'About Secure BDRS',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.admin_panel_settings, color: Colors.blue[600], size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Secure Birth & Death Registration System',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              'A comprehensive system for managing birth and death records in Kajiado County.',
              style: GoogleFonts.poppins(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Save current data before logout (don't clear it)
              final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
              // Ensure data is saved to storage
              await recordsProvider.forceSave();
              // Also clear auth
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              Get.offAll(() => const LoginScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            ),
          ],
        ),
    );
  }
}

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'All Records',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
            tabs: const [
              Tab(text: 'All', icon: Icon(Icons.list, size: 18)),
              Tab(text: 'Birth', icon: Icon(Icons.child_care, size: 18)),
              Tab(text: 'Death', icon: Icon(Icons.airline_seat_flat, size: 18)),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllRecordsTab(),
          _buildBirthRecordsTab(),
          _buildDeathRecordsTab(),
        ],
      ),
    );
  }

  Widget _buildAllRecordsTab() {
    return Consumer<RecordsProvider>(
      builder: (context, recordsProvider, child) {
        final allRecords = [
          ...recordsProvider.births.map((record) => _RecordItem(
            type: 'Birth',
            name: record.childName,
            date: record.dateOfBirth,
            place: record.placeOfBirth,
            color: Colors.blue[600]!,
            icon: Icons.child_care,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.birthDetail,
              arguments: record,
            ),
          )),
          ...recordsProvider.deaths.map((record) => _RecordItem(
            type: 'Death',
            name: record.name,
            date: record.dateOfDeath,
            place: record.placeOfDeath,
            color: Colors.red[600]!,
            icon: Icons.airline_seat_flat,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.deathDetail,
              arguments: record,
            ),
          )),
        ];

        if (allRecords.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            _buildStatsHeader(recordsProvider),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allRecords.length,
                itemBuilder: (context, index) {
                  return allRecords[index].animate().slideX(
                    delay: (200 + (index * 100)).ms,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBirthRecordsTab() {
    return Consumer<RecordsProvider>(
      builder: (context, recordsProvider, child) {
        if (recordsProvider.births.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            _buildStatsHeader(recordsProvider),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recordsProvider.births.length,
                itemBuilder: (context, index) {
                  final record = recordsProvider.births[index];
                  return _RecordItem(
                    type: 'Birth',
                    name: record.childName,
                    date: record.dateOfBirth,
                    place: record.placeOfBirth,
                    color: Colors.blue[600]!,
                    icon: Icons.child_care,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.birthDetail,
                      arguments: record,
                    ),
                  ).animate().slideX(delay: (200 + (index * 100)).ms);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeathRecordsTab() {
    return Consumer<RecordsProvider>(
      builder: (context, recordsProvider, child) {
        if (recordsProvider.deaths.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recordsProvider.deaths.length,
          itemBuilder: (context, index) {
            final record = recordsProvider.deaths[index];
            return _RecordItem(
              type: 'Death',
              name: record.name,
              date: record.dateOfDeath,
              place: record.placeOfDeath,
              color: Colors.red[600]!,
              icon: Icons.airline_seat_flat,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.deathDetail,
                arguments: record,
              ),
            ).animate().slideX(delay: (200 + (index * 100)).ms);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 60,
              color: Colors.green[600],
            ),
          ).animate().scale(delay: 200.ms),
          const SizedBox(height: 24),
          Text(
            'No Records Yet',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Start by registering birth or death records',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(RecordsProvider recordsProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text('Total:', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('${recordsProvider.births.length + recordsProvider.deaths.length}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(width: 16),
                _buildStatItem('Birth', recordsProvider.births.length, Colors.blue[100]!),
                const SizedBox(width: 8),
                _buildStatItem('Death', recordsProvider.deaths.length, Colors.red[100]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $count',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecordItem extends StatelessWidget {
  final String type;
  final String name;
  final DateTime date;
  final String place;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _RecordItem({
    required this.type,
    required this.name,
    required this.date,
    required this.place,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.toLocal().toString().split(' ')[0]} • $place',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecordsSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context, query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context, query);
  }

  Widget _buildSearchResults(BuildContext context, String searchQuery) {
    if (searchQuery.isEmpty) {
      return Center(
        child: Text(
          'Enter a name to search',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Consumer<RecordsProvider>(
      builder: (context, recordsProvider, child) {
        final birthResults = recordsProvider.births
            .where((record) => record.childName.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

        final deathResults = recordsProvider.deaths
            .where((record) => record.name.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

        if (birthResults.isEmpty && deathResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No results found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (birthResults.isNotEmpty) ...[
              Text(
                'Birth Records',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(height: 8),
              ...birthResults.map((record) => _RecordItem(
                type: 'Birth',
                name: record.childName,
                date: record.dateOfBirth,
                place: record.placeOfBirth,
                color: Colors.blue[600]!,
                icon: Icons.child_care,
                onTap: () {
                  close(context, null);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.birthDetail,
                    arguments: record,
                  );
                },
              )),
              const SizedBox(height: 16),
            ],
            if (deathResults.isNotEmpty) ...[
              Text(
                'Death Records',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 8),
              ...deathResults.map((record) => _RecordItem(
                type: 'Death',
                name: record.name,
                date: record.dateOfDeath,
                place: record.placeOfDeath,
                color: Colors.red[600]!,
                icon: Icons.airline_seat_flat,
                onTap: () {
                  close(context, null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Death detail screen coming soon",
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                },
              )),
            ],
          ],
        );
      },
    );
  }
}

class CertificatePage extends StatefulWidget {
  const CertificatePage({super.key});

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  Future<void> _toggleCertificateIssued({
    required bool isBirth,
    required String recordId,
    required bool currentStatus,
  }) async {
    final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final issuer = authProvider.user?.name?.isNotEmpty == true
        ? authProvider.user!.name
        : authProvider.user?.email ?? 'Administrator';

    if (isBirth) {
      await recordsProvider.markBirthCertificateStatus(
        recordId: recordId,
        issued: !currentStatus,
        issuedBy: !currentStatus ? issuer : null,
      );
    } else {
      await recordsProvider.markDeathCertificateStatus(
        recordId: recordId,
        issued: !currentStatus,
        issuedBy: !currentStatus ? issuer : null,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !currentStatus
              ? 'Certificate marked as issued'
              : 'Certificate moved back to pending',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: !currentStatus ? Colors.green[600] : Colors.orange[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Certificates',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [],
      ),
      body: Consumer<RecordsProvider>(
        builder: (context, recordsProvider, child) {
          final dateFormatter = DateFormat('yyyy-MM-dd');

          final allRecords = [
            ...recordsProvider.births.map((record) => _CertificateItem(
              type: 'Birth Certificate',
              name: record.childName,
              date: record.dateOfBirth,
              recordId: record.id,
              registrationNumber: _generateCertificateNumber(),
              color: const Color(0xFF3B82F6),
              icon: Icons.child_care,
              onPrint: () => _printCertificate(context, record),
              issued: record.certificateIssued,
              issuedDate: record.certificateIssuedDate,
              issuedBy: record.certificateIssuedBy,
              onToggleIssued: () => _toggleCertificateIssued(
                isBirth: true,
                recordId: record.id,
                currentStatus: record.certificateIssued,
              ),
              infoRows: [
                _CertificateField('Child Name', record.childName),
                _CertificateField('Date of Birth', dateFormatter.format(record.dateOfBirth)),
                _CertificateField('Place of Birth', record.placeOfBirth),
                _CertificateField('Gender', record.gender),
                _CertificateField('Registration No.', record.registrationNumber),
                if (record.fatherName.isNotEmpty)
                  _CertificateField('Father Name', record.fatherName),
                if (record.fatherNationalId.isNotEmpty)
                  _CertificateField('Father ID', record.fatherNationalId),
                if (record.motherName.isNotEmpty)
                  _CertificateField('Mother Name', record.motherName),
                if (record.motherNationalId.isNotEmpty)
                  _CertificateField('Mother ID', record.motherNationalId),
                if (record.registrar != null && record.registrar!.isNotEmpty)
                  _CertificateField('Registrar', record.registrar!),
                if (record.registrationDate != null)
                  _CertificateField('Registration Date', dateFormatter.format(record.registrationDate!)),
              ],
            )),
            ...recordsProvider.deaths.map((record) => _CertificateItem(
              type: 'Death Certificate',
              name: record.name,
              date: record.dateOfDeath,
              recordId: record.id,
              registrationNumber: _generateCertificateNumber(),
              color: const Color(0xFF8B5CF6),
              icon: Icons.airline_seat_flat,
              onPrint: () => _printCertificate(context, record),
              issued: record.certificateIssued,
              issuedDate: record.certificateIssuedDate,
              issuedBy: record.certificateIssuedBy,
              onToggleIssued: () => _toggleCertificateIssued(
                isBirth: false,
                recordId: record.id,
                currentStatus: record.certificateIssued,
              ),
              infoRows: [
                _CertificateField('Name', record.name),
                _CertificateField('Date of Death', dateFormatter.format(record.dateOfDeath)),
                _CertificateField('Place of Death', record.placeOfDeath),
                if (record.cause.isNotEmpty)
                  _CertificateField('Cause', record.cause),
                _CertificateField('Registration No.', record.registrationNumber),
                if (record.gender != null && record.gender!.isNotEmpty)
                  _CertificateField('Gender', record.gender!),
                if (record.age != null)
                  _CertificateField('Age', '${record.age} years'),
                if (record.hospital != null && record.hospital!.isNotEmpty)
                  _CertificateField('Hospital', record.hospital!),
                if (record.idNumber != null && record.idNumber!.isNotEmpty)
                  _CertificateField('ID Number', record.idNumber!),
                if (record.familyName != null && record.familyName!.isNotEmpty)
                  _CertificateField('Next of Kin', record.familyName!),
                if (record.familyRelation != null && record.familyRelation!.isNotEmpty)
                  _CertificateField('Relation', record.familyRelation!),
                if (record.familyPhone != null && record.familyPhone!.isNotEmpty)
                  _CertificateField('Contact', record.familyPhone!),
              ],
            )),
          ];

          if (allRecords.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildStatsHeader(recordsProvider),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allRecords.length,
                  itemBuilder: (context, index) {
                    return allRecords[index].animate().slideX(
                      delay: (200 + (index * 100)).ms,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.purple[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified,
              size: 60,
              color: Colors.purple[600],
            ),
          ).animate().scale(delay: 200.ms),
          const SizedBox(height: 24),
          Text(
            'No Certificates Yet',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Create birth or death records to generate certificates',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(RecordsProvider recordsProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Certificates',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${recordsProvider.births.length + recordsProvider.deaths.length}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatItem('Birth', recordsProvider.births.length, Colors.blue[100]!),
                    const SizedBox(width: 16),
                    _buildStatItem('Death', recordsProvider.deaths.length, Colors.red[100]!),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.verified,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    ).animate().slideY(delay: 200.ms);
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $count',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _printCertificate(BuildContext context, dynamic record) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
              const SizedBox(height: 16),
              Text(
                'Generating PDF certificate...',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ],
          ),
        ),
      );

      // Generate PDF
      final pdf = await _generatePdfCertificate(record);

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show print dialog
      if (context.mounted) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'PDF certificate ready for printing',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error generating PDF: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<pw.Document> _generatePdfCertificate(dynamic record) async {
    final pdf = pw.Document();

    if (record is BirthRecord) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'BIRTH CERTIFICATE',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // Certificate Content
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildPdfSection('Certificate ID', record.id),
                  _buildPdfSection('Child Name', record.childName),
                  _buildPdfSection('Date of Birth', record.dateOfBirth.toLocal().toString().split(' ')[0]),
                  _buildPdfSection('Place of Birth', record.placeOfBirth),
                  _buildPdfSection('Gender', record.gender),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "Parents' Information",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _buildPdfSection('Father\'s Name', record.fatherName),
                  _buildPdfSection('Father\'s National ID', record.fatherNationalId),
                  _buildPdfSection('Mother\'s Name', record.motherName),
                  _buildPdfSection('Mother\'s National ID', record.motherNationalId),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  _buildPdfSection('Registration Number', record.registrationNumber),
                  _buildPdfSection('Registration Date', record.registrationDate?.toLocal().toString().split(' ')[0] ?? 'N/A'),
                  _buildPdfSection('Registrar', record.registrar ?? 'N/A'),
                  pw.SizedBox(height: 30),
                  pw.Center(
                    child: pw.Text(
                      'This is to certify that the above information is true and correct.',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Generated on: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Secure BDRS System',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );
    } else if (record is DeathRecord) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'DEATH CERTIFICATE',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red900,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // Certificate Content
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildPdfSection('Certificate ID', record.id),
                  _buildPdfSection('Deceased Name', record.name),
                  _buildPdfSection('Date of Death', record.dateOfDeath.toLocal().toString().split(' ')[0]),
                  _buildPdfSection('Place of Death', record.placeOfDeath),
                  _buildPdfSection('Cause of Death', record.cause),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  _buildPdfSection('Registration Number', record.registrationNumber),
                  if (record.idNumber != null) _buildPdfSection('ID Number', record.idNumber!),
                  if (record.hospital != null) _buildPdfSection('Hospital', record.hospital!),
                  pw.SizedBox(height: 30),
                  pw.Center(
                    child: pw.Text(
                      'This is to certify that the above information is true and correct.',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Generated on: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Secure BDRS System',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );
    }

    return pdf;
  }

  pw.Widget _buildPdfSection(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _generateCertificateContent(dynamic record) {
    if (record is BirthRecord) {
      return '''
BIRTH CERTIFICATE
=================

Certificate ID: ${record.id}
Child Name: ${record.childName}
Date of Birth: ${record.dateOfBirth.toLocal().toString().split(' ')[0]}
Place of Birth: ${record.placeOfBirth}
Gender: ${record.gender}
Weight: ${record.weight} kg
Height: ${record.height} cm

Father's Name: ${record.fatherName}
Mother's Name: ${record.motherName}
Father's National ID: ${record.fatherNationalId}
Mother's National ID: ${record.motherNationalId}

Registration Number: ${record.registrationNumber}
Registration Date: ${record.registrationDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}
Registrar: ${record.registrar ?? 'N/A'}

This is to certify that the above information is true and correct.

Generated on: ${DateTime.now().toLocal().toString().split(' ')[0]}
Secure BDRS System
      ''';
    } else if (record is DeathRecord) {
      return '''
DEATH CERTIFICATE
=================

Certificate ID: ${record.id}
Deceased Name: ${record.name}
Date of Death: ${record.dateOfDeath.toLocal().toString().split(' ')[0]}
Place of Death: ${record.placeOfDeath}
Cause of Death: ${record.cause}

Registration Number: ${record.registrationNumber}

This is to certify that the above information is true and correct.

Generated on: ${DateTime.now().toLocal().toString().split(' ')[0]}
Secure BDRS System
      ''';
    }
    return 'Certificate content not available';
  }
}

class _CertificateItem extends StatelessWidget {
  final String type;
  final String name;
  final DateTime date;
  final String recordId;
  final String registrationNumber;
  final Color color;
  final IconData icon;
  final VoidCallback onPrint;
  final VoidCallback onToggleIssued;
  final bool issued;
  final DateTime? issuedDate;
  final String? issuedBy;
  final List<_CertificateField> infoRows;

  const _CertificateItem({
    required this.type,
    required this.name,
    required this.date,
    required this.recordId,
    required this.registrationNumber,
    required this.color,
    required this.icon,
    required this.onPrint,
    required this.onToggleIssued,
    required this.issued,
    this.issuedDate,
    this.issuedBy,
    required this.infoRows,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = issued ? Colors.green : Colors.orange;
    final statusLabel = issued ? 'Issued' : 'Pending';
    final isBirth = type.toLowerCase().contains('birth');
    final baseColor = isBirth ? const Color(0xFF2563EB) : const Color(0xFFDC2626);
    final accentColor = issued ? const Color(0xFF16A34A) : baseColor;
    final dateFormatter = DateFormat('dd MMM yyyy');
    final certificateDate = issuedDate ?? DateTime.now();
    final certificateDateLabel = DateFormat('yyyy-MM-dd').format(certificateDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: baseColor, width: 3),
            ),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: baseColor.withOpacity(0.45), width: 2),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Republic of Kenya',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ministry of Health  •  Civil Registration Department',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    type.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: baseColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    height: 2,
                    width: 200,
                    margin: const EdgeInsets.only(top: 8),
                    color: baseColor,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Certificate No: $registrationNumber',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: baseColor,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...infoRows.map((field) => _buildCertificateInfoLine(field, baseColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          _buildSeal(baseColor),
                          const SizedBox(height: 16),
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: baseColor.withOpacity(0.4)),
                            ),
                            child: Icon(Icons.qr_code_2, size: 44, color: baseColor),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Scan to Verify',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Generated by Secure BDRS System',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Wrap(
              spacing: 14,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const SizedBox.shrink(),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: _buildActionButton(
                    context: context,
                    colors: [Colors.green[600]!, Colors.green[700]!],
                    icon: Icons.print,
                    label: 'Print PDF',
                    onTap: onPrint,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _buildActionButton(
                    context: context,
                    colors: issued
                        ? [Colors.orange[500]!, Colors.deepOrange[600]!]
                        : [baseColor, baseColor.withOpacity(0.8)],
                    icon: issued ? Icons.undo : Icons.verified,
                    label: issued ? 'Mark Pending' : 'Mark Issued',
                    onTap: onToggleIssued,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required List<Color> colors,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeal(Color color) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'OFFICIAL',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Container(
              width: 40,
              height: 1,
              color: color,
              margin: const EdgeInsets.symmetric(vertical: 4),
            ),
            Text(
              'SEAL',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateInfoLine(_CertificateField field, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '${field.label}:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              field.value,
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
}

String _generateCertificateNumber() {
  final random = Random(DateTime.now().microsecondsSinceEpoch);
  final number = random.nextInt(9000000) + 1000000; // always 7 digits
  return number.toString();
}

class _CertificateField {
  final String label;
  final String value;

  const _CertificateField(this.label, this.value);
}

