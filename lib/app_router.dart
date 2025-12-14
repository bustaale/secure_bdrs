import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/create_account_screen.dart';
import 'screens/birth/birth_list_screen.dart';
import 'screens/birth/birth_form_screen.dart';
import 'screens/birth/birth_detail_screen.dart';
import 'screens/death/death_list_screen.dart';
import 'screens/death/death_form_screen.dart';
import 'screens/death/death_detail_screen.dart';
import 'screens/advanced_search_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/analytics/advanced_analytics_screen.dart';
import 'screens/auth/admin_login_screen.dart';
import 'screens/admin/admin_review_screen.dart';
import 'screens/admin_screen.dart';
import 'main.dart'; // ✅ DashboardScreen is defined in main.dart

class AppRoutes {
  static const login = '/';
  static const createAccount = '/create-account';
  static const adminLogin = '/admin-login';
  static const admin = '/admin';
  static const adminReview = '/admin-review';
  static const dashboard = '/dashboard';
  static const birthList = '/births';
  static const birthForm = '/births/new';
  static const birthDetail = '/births/detail';
  static const deathList = '/deaths';
  static const deathForm = '/deaths/new';
  static const deathDetail = '/deaths/detail';
  static const certificate = '/certificate';
  static const advancedSearch = '/advanced-search';
  static const userManagement = '/user-management';
  static const advancedAnalytics = '/advanced-analytics';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.createAccount:
        return MaterialPageRoute(builder: (_) => const CreateAccountScreen());

      case AppRoutes.adminLogin:
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen());

      case AppRoutes.admin:
        return MaterialPageRoute(builder: (_) => const AdminScreen());

      case AppRoutes.adminReview:
        return MaterialPageRoute(builder: (_) => const AdminReviewScreen());

      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case AppRoutes.birthList:
        return MaterialPageRoute(builder: (_) => const BirthListScreen());

      case AppRoutes.birthForm:
        return MaterialPageRoute(builder: (_) => const BirthFormScreen());

      case AppRoutes.birthDetail:
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => BirthDetailScreen(record: args as dynamic),
        );

      case AppRoutes.deathList:
        return MaterialPageRoute(builder: (_) => const DeathListScreen());

      case AppRoutes.deathForm:
        return MaterialPageRoute(builder: (_) => const DeathFormScreen());

      case AppRoutes.deathDetail:
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => DeathDetailScreen(record: args as dynamic),
        );

      case AppRoutes.certificate:
        return MaterialPageRoute(builder: (_) => const CertificatePage());

      case AppRoutes.advancedSearch:
        return MaterialPageRoute(builder: (_) => const AdvancedSearchScreen());

      case AppRoutes.userManagement:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());

      case AppRoutes.advancedAnalytics:
        return MaterialPageRoute(builder: (_) => const AdvancedAnalyticsScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
