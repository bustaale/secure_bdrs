import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../app_router.dart';
import '../../services/biometric_service.dart';
import '../../screens/user_management_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String email = "";
  String password = "";
  bool _obscure = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String? _savedEmail;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    final savedEmail = await BiometricService.getSavedEmail();
    
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _savedEmail = savedEmail;
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.login(email, password);
    if (ok) {
      // Ask user if they want to enable biometric after successful login
      if (_biometricAvailable && !_biometricEnabled) {
        _askToEnableBiometric();
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login failed — check credentials")),
        );
      }
    }
  }

  Future<void> _askToEnableBiometric() async {
    if (!mounted) return;
    
    final shouldEnable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Enable Biometric Login?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Would you like to enable fingerprint login for faster access?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Not Now', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Enable', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldEnable == true) {
      try {
        await BiometricService.enableBiometric(email, password);
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Biometric login enabled successfully",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } catch (e) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Failed to enable biometric: $e",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  Future<void> _loginWithBiometric() async {
    try {
      // Show biometric authentication dialog
      final credentials = await BiometricService.authenticate();
      
      if (credentials != null) {
        // Use the saved credentials to login
        setState(() {
          email = credentials['email']!;
          password = credentials['password']!;
        });
        
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final ok = await auth.login(credentials['email']!, credentials['password']!);
        
        if (ok) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          }
        } else {
          if (mounted) {
            Fluttertoast.showToast(
              msg: "Biometric login failed. Please use password.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: e.toString().replaceAll('Exception: ', ''),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Image.asset(
                            'assets/images/profile.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.admin_panel_settings,
                                size: 50,
                                color: Colors.blue[600],
                              );
                            },
                          ),
                        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 16),
                        Text(
                          "Secure BDRS",
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        Text(
                          "Birth & Death Registration System",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 8),
                        Text(
                          "Kajiado County - National Civil Data Management",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 600.ms),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Login Form
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Welcome Back",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 800.ms),
                          const SizedBox(height: 8),
                          Text(
                            "Sign in to continue",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 1000.ms),
                          const SizedBox(height: 32),
                          
                          // Email Field
                          TextFormField(
                            initialValue: email,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined, color: Colors.blue[600]),
                              labelText: "Email Address",
                              labelStyle: GoogleFonts.poppins(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? "Enter email" : null,
                            onSaved: (v) => email = v!.trim(),
                          ).animate().slideX(delay: 1200.ms),
                          const SizedBox(height: 20),
                          
                          // Password Field
                          TextFormField(
                            initialValue: password,
                            obscureText: _obscure,
                            style: GoogleFonts.poppins(),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.blue[600]),
                              labelText: "Password",
                              labelStyle: GoogleFonts.poppins(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.blue[600],
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? "Enter password" : null,
                            onSaved: (v) => password = v ?? "",
                          ).animate().slideX(delay: 1400.ms),
                          const SizedBox(height: 32),
                          
                          // Login Button
                          auth.loading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                                  ),
                                )
                              : Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.blue[600]!, Colors.purple[600]!],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      "Sign In",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ).animate().scale(delay: 1600.ms),
                          const SizedBox(height: 24),
                          
                          // Sign Up Button
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue[600]!, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.createAccount);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "Create New Account",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 1800.ms),
                          
                          const SizedBox(height: 16),
                          
                          // Admin/User Management Links
                          Column(
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.adminLogin);
                                },
                                child: Text(
                                  "Admin Login",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Show dialog to check if user wants to manage users
                                  // After login, they can access it
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Row(
                                        children: [
                                          Icon(Icons.admin_panel_settings, color: Colors.red[600]),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Admin Only Access',
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.red[200]!),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Only administrators can access User Management.',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.red[900],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'User Management allows you to:',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildFeatureItem('Add new users'),
                                          _buildFeatureItem('Edit user roles and permissions'),
                                          _buildFeatureItem('Deactivate users'),
                                          _buildFeatureItem('View all user activity'),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Would you like to go to Admin Login?',
                                            style: GoogleFonts.poppins(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(
                                            'Cancel',
                                            style: GoogleFonts.poppins(),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.pushNamed(context, AppRoutes.adminLogin);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[600],
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            'Go to Admin Login',
                                            style: GoogleFonts.poppins(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Text(
                                  "User Management",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple[600],
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 1900.ms),
                          
                          // Biometric Login Option
                          if (_biometricAvailable && _biometricEnabled) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "OR",
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green[600]!, width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _loginWithBiometric,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.fingerprint,
                                  color: Colors.green[600],
                                  size: 28,
                                ),
                                label: Text(
                                  "Login with Biometric",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[600],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 2000.ms),
                          ],
                        ],
                      ),
                    ),
                  ).animate().slideY(delay: 1000.ms),
                  
                  const SizedBox(height: 40),
                  
                  // Footer
                  Text(
                    "© 2025 Kajiado County Government",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ).animate().fadeIn(delay: 2000.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
