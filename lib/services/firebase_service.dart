import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/birth_record.dart';
import '../models/death_record.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _birthsCollection = 'births';
  static const String _deathsCollection = 'deaths';
  static const String _adminEmail = 'moh4383531@gmail.com';

  // Birth Records Operations
  static Future<void> addBirthRecord(BirthRecord record) async {
    try {
      final data = record.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      print('📤 Attempting to save birth record to Firestore: ${record.id}');
      print('📤 Collection: $_birthsCollection');
      print('📤 Data keys: ${data.keys.toList()}');
      
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ User not authenticated - Firestore requires authentication');
        throw Exception('User not authenticated. Please login to save records to cloud.');
      }
      print('✅ User authenticated: ${currentUser.email}');
      
      await _firestore
          .collection(_birthsCollection)
          .doc(record.id)
          .set(data);
      
      print('✅ Successfully saved birth record to Firestore: ${record.id}');
    } on FirebaseException catch (e) {
      print('❌ Firebase error adding birth record: ${e.code} - ${e.message}');
      throw Exception('Firebase error: ${e.code} - ${e.message}');
    } catch (e) {
      print('❌ Error adding birth record to Firestore: $e');
      throw Exception('Error adding birth record: $e');
    }
  }

  static Future<List<BirthRecord>> getBirthRecords() async {
    try {
      final snapshot = await _firestore
          .collection(_birthsCollection)
          .orderBy('dateOfBirth', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return BirthRecord.fromMap(data as Map<String, dynamic>);
          })
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.message?.contains('API has not been used') == true) {
        // Firestore API not enabled - return empty list, will use local storage
        print('⚠️ Firestore API not enabled. Using local storage.');
        return [];
      }
      throw Exception('Error fetching birth records: ${e.message}');
    } catch (e) {
      // For other errors, return empty list to fallback to local storage
      print('⚠️ Firestore error: $e. Using local storage.');
      return [];
    }
  }

  static Stream<List<BirthRecord>> streamBirthRecords() {
    try {
      return _firestore
          .collection(_birthsCollection)
          .orderBy('dateOfBirth', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return BirthRecord.fromMap(data as Map<String, dynamic>);
              })
              .toList())
          .handleError((error) {
            if (error is FirebaseException && 
                (error.code == 'permission-denied' || 
                 error.message?.contains('API has not been used') == true)) {
              print('⚠️ Firestore API not enabled. Using local storage.');
              return <BirthRecord>[];
            }
            print('⚠️ Firestore stream error: $error');
            return <BirthRecord>[];
          });
    } catch (e) {
      print('⚠️ Firestore stream setup error: $e');
      return Stream.value(<BirthRecord>[]);
    }
  }

  static Future<BirthRecord?> getBirthRecordById(String id) async {
    try {
      final doc = await _firestore.collection(_birthsCollection).doc(id).get();
      if (doc.exists) {
        final data = doc.data();
        return data != null ? BirthRecord.fromMap(data as Map<String, dynamic>) : null;
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching birth record: $e');
    }
  }

  static Future<void> updateBirthRecord(BirthRecord record) async {
    try {
      final updateData = Map<String, dynamic>.from(record.toMap());
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(_birthsCollection)
          .doc(record.id)
          .update(updateData);
    } catch (e) {
      throw Exception('Error updating birth record: $e');
    }
  }

  static Future<void> deleteBirthRecord(String id) async {
    try {
      await _firestore.collection(_birthsCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting birth record: $e');
    }
  }

  // Death Records Operations
  static Future<void> addDeathRecord(DeathRecord record) async {
    try {
      final data = record.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      print('📤 Attempting to save death record to Firestore: ${record.id}');
      print('📤 Collection: $_deathsCollection');
      print('📤 Data keys: ${data.keys.toList()}');
      
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ User not authenticated - Firestore requires authentication');
        throw Exception('User not authenticated. Please login to save records to cloud.');
      }
      print('✅ User authenticated: ${currentUser.email}');
      
      await _firestore
          .collection(_deathsCollection)
          .doc(record.id)
          .set(data);
      
      print('✅ Successfully saved death record to Firestore: ${record.id}');
    } on FirebaseException catch (e) {
      print('❌ Firebase error adding death record: ${e.code} - ${e.message}');
      throw Exception('Firebase error: ${e.code} - ${e.message}');
    } catch (e) {
      print('❌ Error adding death record to Firestore: $e');
      throw Exception('Error adding death record: $e');
    }
  }

  static Future<List<DeathRecord>> getDeathRecords() async {
    try {
      final snapshot = await _firestore
          .collection(_deathsCollection)
          .orderBy('dateOfDeath', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return DeathRecord.fromMap(data as Map<String, dynamic>);
          })
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.message?.contains('API has not been used') == true) {
        // Firestore API not enabled - return empty list, will use local storage
        print('⚠️ Firestore API not enabled. Using local storage.');
        return [];
      }
      throw Exception('Error fetching death records: ${e.message}');
    } catch (e) {
      // For other errors, return empty list to fallback to local storage
      print('⚠️ Firestore error: $e. Using local storage.');
      return [];
    }
  }

  static Stream<List<DeathRecord>> streamDeathRecords() {
    try {
      return _firestore
          .collection(_deathsCollection)
          .orderBy('dateOfDeath', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return DeathRecord.fromMap(data as Map<String, dynamic>);
              })
              .toList())
          .handleError((error) {
            if (error is FirebaseException && 
                (error.code == 'permission-denied' || 
                 error.message?.contains('API has not been used') == true)) {
              print('⚠️ Firestore API not enabled. Using local storage.');
              return <DeathRecord>[];
            }
            print('⚠️ Firestore stream error: $error');
            return <DeathRecord>[];
          });
    } catch (e) {
      print('⚠️ Firestore stream setup error: $e');
      return Stream.value(<DeathRecord>[]);
    }
  }

  static Future<DeathRecord?> getDeathRecordById(String id) async {
    try {
      final doc = await _firestore.collection(_deathsCollection).doc(id).get();
      if (doc.exists) {
        final data = doc.data();
        return data != null ? DeathRecord.fromMap(data as Map<String, dynamic>) : null;
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching death record: $e');
    }
  }

  static Future<void> updateDeathRecord(DeathRecord record) async {
    try {
      final updateData = Map<String, dynamic>.from(record.toMap());
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(_deathsCollection)
          .doc(record.id)
          .update(updateData);
    } catch (e) {
      throw Exception('Error updating death record: $e');
    }
  }

  static Future<void> deleteDeathRecord(String id) async {
    try {
      await _firestore.collection(_deathsCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting death record: $e');
    }
  }

  // Get admin email
  static String get adminEmail => _adminEmail;

  // Statistics
  static Future<Map<String, int>> getStatistics() async {
    try {
      final birthsSnapshot = await _firestore
          .collection(_birthsCollection)
          .count()
          .get();
      
      final deathsSnapshot = await _firestore
          .collection(_deathsCollection)
          .count()
          .get();

      return {
        'births': birthsSnapshot.count ?? 0,
        'deaths': deathsSnapshot.count ?? 0,
        'total': (birthsSnapshot.count ?? 0) + (deathsSnapshot.count ?? 0),
      };
    } catch (e) {
      throw Exception('Error fetching statistics: $e');
    }
  }
}

