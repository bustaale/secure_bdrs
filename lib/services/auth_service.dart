import "dart:async";
import "package:firebase_auth/firebase_auth.dart" as firebase_auth;
import "package:cloud_firestore/cloud_firestore.dart";
import "../models/user.dart";
import "account_storage.dart";

/// Firebase Authentication Service
/// Handles user authentication using Firebase Auth
class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  /// Login with email and password using Firebase Auth
  Future<User?> login(String email, String password) async {
    try {
      // First try Firebase Auth with timeout
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Login request timed out. Please check your internet connection.');
        },
      );

      if (credential.user != null) {
        final firebaseUser = credential.user!;
        // Get user data from Firestore with timeout
        DocumentSnapshot? userDoc;
        try {
          userDoc = await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .get()
              .timeout(const Duration(seconds: 10));
        } on TimeoutException {
          // If Firestore times out, use default user data
          print('Warning: Firestore read timed out, using default user data');
          userDoc = null;
        } catch (e) {
          print('Warning: Firestore read error: $e');
          userDoc = null;
        }

        if (userDoc != null && userDoc.exists) {
          final userData = (userDoc.data() as Map<String, dynamic>?) ?? {};
          return User(
            id: firebaseUser.uid,
            name: userData['name'] ?? firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? email,
            role: userData['role'] ?? 'clerk',
          );
        } else {
          // Create user document if it doesn't exist (with timeout)
          try {
            await _firestore.collection('users').doc(firebaseUser.uid).set({
              'name': firebaseUser.displayName ?? 'User',
              'email': firebaseUser.email ?? email,
              'role': 'clerk',
              'createdAt': FieldValue.serverTimestamp(),
            }).timeout(const Duration(seconds: 10));
          } catch (e) {
            // If Firestore write fails, still return user
            print('Warning: Could not write to Firestore: $e');
          }

          return User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? email,
            role: 'clerk',
          );
        }
      }
      return null;
    } on TimeoutException catch (e) {
      // Timeout - fall back to local storage
      print('Login timeout: ${e.message}');
      return await _tryLocalLogin(email, password);
    } on firebase_auth.FirebaseAuthException catch (e) {
      // If Firebase Auth fails, fall back to local storage for backward compatibility
      print('Firebase Auth error: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return await _tryLocalLogin(email, password);
      }
      // For other Firebase errors, still try local login
      return await _tryLocalLogin(email, password);
    } catch (e) {
      // Fallback to local storage on any error
      print('Login error: $e');
      return await _tryLocalLogin(email, password);
    }
  }

  /// Try local login (default credentials or stored accounts)
  Future<User?> _tryLocalLogin(String email, String password) async {
    try {
      // Check default credentials
      if (email.toLowerCase() == "clerk@kajiado.go.ke" && password == "admin123") {
        return User(id: "1", name: "Kajiado Clerk", email: email, role: "clerk");
      }
      if (email.toLowerCase() == "admin@kajiado.go.ke" && password == "admin123") {
        return User(id: "0", name: "County Admin", email: email, role: "admin");
      }

      // Check stored accounts
      return await AccountStorage.validateLogin(email, password);
    } catch (e) {
      print('Local login error: $e');
      return null;
    }
  }

  /// Create account with Firebase Auth
  Future<User?> createAccountWithFirebase(String name, String email, String password) async {
    try {
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        final firebaseUser = credential.user!;
        
        // Try to update display name (non-blocking - don't wait for it)
        firebaseUser.updateDisplayName(name).catchError((e) {
          print('Warning: Could not update display name: $e');
        });

        // Create user document in Firestore (with timeout - non-blocking)
        _firestore.collection('users').doc(firebaseUser.uid).set({
          'name': name,
          'email': email.trim(),
          'role': 'clerk', // Default role
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('Warning: Firestore write timed out, but user was created successfully');
          },
        ).catchError((firestoreError) {
          // Log error but don't fail account creation - Firebase Auth user is already created
          print('Warning: Could not write to Firestore: $firestoreError');
          print('User account was created successfully in Firebase Auth');
        });

        // Return user model immediately (Firebase Auth user is created, which is the most important part)
        return User(
          id: firebaseUser.uid,
          name: name,
          email: firebaseUser.email ?? email,
          role: 'clerk',
        );
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception('Firebase Auth Error: ${e.message} (Code: ${e.code})');
    } catch (e) {
      throw Exception('Error creating account: $e');
    }
  }

  /// Logout from Firebase
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // Ignore errors during logout
      print('Error during logout: $e');
    }
  }

  /// Get current user from Firebase
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = (userDoc.data() as Map<String, dynamic>?) ?? {};
        return User(
          id: firebaseUser.uid,
          name: userData['name'] ?? firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          role: userData['role'] ?? 'clerk',
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception('Firebase Auth Error: ${e.message}');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String name, {String? email}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Update display name
      await user.updateDisplayName(name);
      await user.reload();

      // Update Firestore
      final updateData = <String, dynamic>{
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (email != null && email != user.email) {
        await user.updateEmail(email);
        updateData['email'] = email;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception('Firebase Auth Error: ${e.message}');
    }
  }
}
