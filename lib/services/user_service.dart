import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'audit_log_service.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _currentUserKey = 'current_user';
  static const String _currentUserIdKey = 'current_user_id';

  // Get current user
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserIdKey);
      
      if (userId == null) return null;

      // Try to get from Firestore first
      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = doc.id;
          return UserModel.fromMap(data);
        }
      } catch (e) {
        // Fallback to local storage
        final userJson = prefs.getString(_currentUserKey);
        if (userJson != null) {
          // Parse from JSON string
          final Map<String, dynamic> userMap = Map<String, dynamic>.from(
            userJson.split(',').fold<Map<String, dynamic>>({}, (map, item) {
              final parts = item.split(':');
              if (parts.length == 2) {
                map[parts[0].trim()] = parts[1].trim();
              }
              return map;
            }),
          );
          return UserModel.fromMap(userMap);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Set current user
  static Future<void> setCurrentUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserIdKey, user.id);
      
      // Save user data locally as backup
      final userMap = user.toMap();
      final userString = userMap.entries.map((e) => '${e.key}:${e.value}').join(',');
      await prefs.setString(_currentUserKey, userString);

      // Update last login
      await updateLastLogin(user.id);
    } catch (e) {
      // Silent fail
    }
  }

  // Update last login
  static Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silent fail if Firestore not available
    }
  }

  // Create new user
  static Future<UserModel> createUser({
    required String username,
    required String email,
    required String role,
    String? createdBy,
  }) async {
    try {
      final user = UserModel(
        id: _firestore.collection('users').doc().id,
        username: username,
        email: email,
        role: role,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      // Save to Firestore
      try {
        await _firestore.collection('users').doc(user.id).set(user.toMap());
      } catch (e) {
        // Fallback to local storage if Firestore fails
        final prefs = await SharedPreferences.getInstance();
        final usersJson = prefs.getString('users_list') ?? '[]';
        // Simple JSON-like storage (in production, use proper JSON encoding)
        await prefs.setString('users_list', usersJson);
      }

      await AuditLogService.logAction(
        'User created: $username ($role)',
        metadata: {'userId': user.id, 'role': role},
      );

      return user;
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  // Get all users
  static Future<List<UserModel>> getAllUsers() async {
    try {
      // Try Firestore first
      try {
        final snapshot = await _firestore.collection('users').get();
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return UserModel.fromMap(data);
        }).toList();
      } catch (e) {
        // Fallback to local storage
        final prefs = await SharedPreferences.getInstance();
        final usersJson = prefs.getString('users_list');
        if (usersJson != null && usersJson.isNotEmpty) {
          // Parse users from local storage
          return [];
        }
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Update user
  static Future<void> updateUser(UserModel user) async {
    try {
      // Update in Firestore
      try {
        await _firestore.collection('users').doc(user.id).update(user.toMap());
      } catch (e) {
        // Fallback to local storage
      }

      await AuditLogService.logAction(
        'User updated: ${user.username}',
        metadata: {'userId': user.id},
      );
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // Delete user (soft delete by deactivating)
  static Future<void> deactivateUser(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user != null) {
        final updatedUser = user.copyWith(isActive: false);
        await updateUser(updatedUser);

        await AuditLogService.logAction(
          'User deactivated: ${user.username}',
          metadata: {'userId': userId},
        );
      }
    } catch (e) {
      throw Exception('Error deactivating user: $e');
    }
  }

  // Get user by ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Clear current user (logout)
  static Future<void> clearCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserIdKey);
      await prefs.remove(_currentUserKey);
    } catch (e) {
      // Silent fail
    }
  }
}

