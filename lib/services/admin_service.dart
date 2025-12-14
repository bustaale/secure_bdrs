import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  static const String _usersCollection = 'users';

  // Get all users
  static Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return User(
          id: doc.id,
          name: data['name'] ?? 'Unknown',
          email: data['email'] ?? '',
          role: data['role'] ?? 'clerk',
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Get active users count
  static Future<int> getActiveUsersCount() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      // Fallback: count all users if isActive field doesn't exist
      try {
        final snapshot = await _firestore.collection(_usersCollection).count().get();
        return snapshot.count ?? 0;
      } catch (e2) {
        return 0;
      }
    }
  }

  // Create user
  static Future<User> createUser(String name, String email, String password, String role) async {
    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        final firebaseUser = credential.user!;
        
        // Update display name
        await firebaseUser.updateDisplayName(name);
        
        // Create user document in Firestore
        await _firestore.collection(_usersCollection).doc(firebaseUser.uid).set({
          'name': name,
          'email': email.trim(),
          'role': role,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return User(
          id: firebaseUser.uid,
          name: name,
          email: email,
          role: role,
        );
      }
      throw Exception('Failed to create user');
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  // Update user
  static Future<void> updateUser(String userId, {String? name, String? role, bool? isActive}) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) {
        updateData['name'] = name;
        // Update Firebase Auth display name
        final user = _auth.currentUser;
        if (user != null && user.uid == userId) {
          await user.updateDisplayName(name);
        }
      }

      if (role != null) {
        updateData['role'] = role;
      }

      if (isActive != null) {
        updateData['isActive'] = isActive;
      }

      await _firestore.collection(_usersCollection).doc(userId).update(updateData);
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // Delete user (deactivate instead of delete)
  static Future<void> deleteUser(String userId) async {
    try {
      // Deactivate instead of deleting
      await _firestore.collection(_usersCollection).doc(userId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Optionally delete Firebase Auth user
      // await _auth.currentUser?.delete();
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Get user by ID
  static Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return User(
          id: doc.id,
          name: data['name'] ?? 'Unknown',
          email: data['email'] ?? '',
          role: data['role'] ?? 'clerk',
        );
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }
}

