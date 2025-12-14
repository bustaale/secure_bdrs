import '../models/user_model.dart';

enum Permission {
  // Record permissions
  createBirthRecord,
  editBirthRecord,
  deleteBirthRecord,
  viewBirthRecord,
  
  createDeathRecord,
  editDeathRecord,
  deleteDeathRecord,
  viewDeathRecord,
  
  // Certificate permissions
  generateCertificate,
  issueCertificate,
  viewCertificates,
  
  // Admin permissions
  viewAdminDashboard,
  manageUsers,
  viewAuditLogs,
  exportData,
  generateReports,
  backupRestore,
  systemSettings,
  
  // Search permissions
  advancedSearch,
}

class PermissionsService {
  // Define role permissions
  static const Map<String, List<Permission>> _rolePermissions = {
    'Admin': [
      // All permissions
      Permission.createBirthRecord,
      Permission.editBirthRecord,
      Permission.deleteBirthRecord,
      Permission.viewBirthRecord,
      Permission.createDeathRecord,
      Permission.editDeathRecord,
      Permission.deleteDeathRecord,
      Permission.viewDeathRecord,
      Permission.generateCertificate,
      Permission.issueCertificate,
      Permission.viewCertificates,
      Permission.viewAdminDashboard,
      Permission.manageUsers,
      Permission.viewAuditLogs,
      Permission.exportData,
      Permission.generateReports,
      Permission.backupRestore,
      Permission.systemSettings,
      Permission.advancedSearch,
    ],
    'Registrar': [
      // Can create, edit, view records and certificates
      Permission.createBirthRecord,
      Permission.editBirthRecord,
      Permission.viewBirthRecord,
      Permission.createDeathRecord,
      Permission.editDeathRecord,
      Permission.viewDeathRecord,
      Permission.generateCertificate,
      Permission.issueCertificate,
      Permission.viewCertificates,
      Permission.exportData,
      Permission.generateReports,
      Permission.advancedSearch,
    ],
    'Clerk': [
      // Can only create and view records
      Permission.createBirthRecord,
      Permission.viewBirthRecord,
      Permission.createDeathRecord,
      Permission.viewDeathRecord,
      Permission.viewCertificates,
      Permission.advancedSearch,
    ],
  };

  // Check if user has a specific permission
  static bool hasPermission(UserModel? user, Permission permission) {
    if (user == null || !user.isActive) {
      return false;
    }

    final userPermissions = _rolePermissions[user.role] ?? [];
    return userPermissions.contains(permission);
  }

  // Check if user has any of the given permissions
  static bool hasAnyPermission(UserModel? user, List<Permission> permissions) {
    return permissions.any((permission) => hasPermission(user, permission));
  }

  // Check if user has all of the given permissions
  static bool hasAllPermissions(UserModel? user, List<Permission> permissions) {
    return permissions.every((permission) => hasPermission(user, permission));
  }

  // Get all permissions for a role
  static List<Permission> getPermissionsForRole(String role) {
    return _rolePermissions[role] ?? [];
  }

  // Check if user can access admin features
  static bool canAccessAdmin(UserModel? user) {
    return hasPermission(user, Permission.viewAdminDashboard);
  }

  // Check if user can manage users
  static bool canManageUsers(UserModel? user) {
    return hasPermission(user, Permission.manageUsers);
  }

  // Check if user can delete records
  static bool canDeleteRecords(UserModel? user) {
    return hasPermission(user, Permission.deleteBirthRecord) ||
           hasPermission(user, Permission.deleteDeathRecord);
  }

  // Check if user can edit records
  static bool canEditRecords(UserModel? user) {
    return hasPermission(user, Permission.editBirthRecord) ||
           hasPermission(user, Permission.editDeathRecord);
  }

  // Check if user can issue certificates
  static bool canIssueCertificates(UserModel? user) {
    return hasPermission(user, Permission.issueCertificate);
  }
}
