import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';

/// Service to initialize Firestore collections structure
/// This creates metadata documents in each collection to make them visible in Firebase Console
class FirebaseSetupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  /// Initialize all collections with metadata documents
  /// This makes collections visible in Firebase Console
  static Future<void> initializeCollections() async {
    try {
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to initialize collections. Please login first.');
      }

      print('🚀 Initializing Firestore collections...');
      print('👤 Authenticated user: ${currentUser.email}');

      // Initialize births collection
      await _initializeCollection(
        collection: 'births',
        metadata: {
          'collectionType': 'births',
          'description': 'Birth registration records',
          'initializedAt': FieldValue.serverTimestamp(),
          'schema': {
            'id': 'string',
            'childName': 'string',
            'dateOfBirth': 'timestamp',
            'gender': 'string',
            'placeOfBirth': 'string',
            'fatherName': 'string',
            'motherName': 'string',
            'approvalStatus': 'string (pending/approved/rejected)',
            'paymentCompleted': 'boolean',
            'certificateIssued': 'boolean',
          },
        },
      );

      // Initialize deaths collection
      await _initializeCollection(
        collection: 'deaths',
        metadata: {
          'collectionType': 'deaths',
          'description': 'Death registration records',
          'initializedAt': FieldValue.serverTimestamp(),
          'schema': {
            'id': 'string',
            'name': 'string',
            'dateOfDeath': 'timestamp',
            'placeOfDeath': 'string',
            'cause': 'string',
            'gender': 'string',
            'certificateIssued': 'boolean',
          },
        },
      );

      // Initialize users collection
      await _initializeCollection(
        collection: 'users',
        metadata: {
          'collectionType': 'users',
          'description': 'User accounts and profiles',
          'initializedAt': FieldValue.serverTimestamp(),
          'schema': {
            'id': 'string',
            'name': 'string',
            'email': 'string',
            'role': 'string (admin/clerk/registrar)',
            'isActive': 'boolean',
            'createdAt': 'timestamp',
            'lastLogin': 'timestamp',
          },
        },
      );

      // Initialize audit_logs collection
      await _initializeCollection(
        collection: 'audit_logs',
        metadata: {
          'collectionType': 'audit_logs',
          'description': 'System audit trail for all admin actions',
          'initializedAt': FieldValue.serverTimestamp(),
          'schema': {
            'id': 'string',
            'action': 'string',
            'userId': 'string',
            'userName': 'string',
            'userEmail': 'string',
            'recordType': 'string (birth/death)',
            'recordId': 'string',
            'timestamp': 'timestamp',
            'metadata': 'object',
          },
        },
      );

      // Initialize notifications collection
      await _initializeCollection(
        collection: 'notifications',
        metadata: {
          'collectionType': 'notifications',
          'description': 'User notifications for approvals, rejections, and system messages',
          'initializedAt': FieldValue.serverTimestamp(),
          'schema': {
            'id': 'string',
            'userId': 'string',
            'title': 'string',
            'message': 'string',
            'type': 'string (approval/rejection/system/payment/certificate)',
            'recordType': 'string (birth/death)',
            'recordId': 'string',
            'isRead': 'boolean',
            'timestamp': 'timestamp',
            'metadata': 'object',
          },
        },
      );

      // Initialize backups collection
      await _initializeCollection(
        collection: 'backups',
        metadata: {
          'collectionType': 'backups',
          'description': 'System backup records',
          'initializedAt': FieldValue.serverTimestamp(),
          'schema': {
            'id': 'string',
            'backupName': 'string',
            'createdAt': 'timestamp',
            'createdBy': 'string',
            'size': 'number',
            'data': 'object',
          },
        },
      );

      print('✅ All Firestore collections initialized successfully!');
      
      // Verify collections were created
      await Future.delayed(const Duration(seconds: 1));
      final status = await checkCollectionsStatus();
      print('📊 Collection Status:');
      status.forEach((collection, exists) {
        print('  ${exists ? "✅" : "❌"} $collection: ${exists ? "created" : "failed"}');
      });
      
      // Check if all collections were created
      final allCreated = status.values.every((exists) => exists);
      if (!allCreated) {
        final failed = status.entries.where((e) => !e.value).map((e) => e.key).join(', ');
        print('⚠️ Some collections failed to initialize: $failed');
        print('📋 Collections status: $status');
        
        // Try to verify by reading the documents
        for (final collection in ['births', 'deaths', 'users', 'audit_logs', 'notifications', 'backups']) {
          try {
            final doc = await _firestore.collection(collection).doc('_metadata').get();
            print('  $collection: ${doc.exists ? "✅ EXISTS" : "❌ NOT FOUND"}');
            if (doc.exists) {
              print('    Data: ${doc.data()}');
            }
          } catch (e) {
            print('  $collection: ❌ ERROR - $e');
          }
        }
        
        throw Exception('Some collections failed to initialize: $failed. Check console logs for details.');
      }
      
      print('✅ All collections verified and created successfully!');
      print('📝 You can now refresh your Firebase Console to see the collections.');
    } on FirebaseException catch (e) {
      print('❌ Firebase error initializing collections:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Plugin: ${e.plugin}');
      
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Please check:\n1. You are logged in\n2. Firestore security rules allow writes\n3. Firestore is enabled in Firebase Console');
      } else if (e.code == 'unavailable') {
        throw Exception('Firestore is unavailable. Please check:\n1. Your internet connection\n2. Firestore is enabled in Firebase Console\n3. Database location is set correctly');
      }
      
      throw Exception('Firebase error (${e.code}): ${e.message}');
    } catch (e) {
      print('❌ Error initializing collections: $e');
      rethrow;
    }
  }

  /// Initialize a single collection with metadata
  static Future<void> _initializeCollection({
    required String collection,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create a metadata document to make collection visible
      final metadataDocRef = _firestore.collection(collection).doc('_metadata');
      
      // Try to read existing document
      DocumentSnapshot? doc;
      try {
        doc = await metadataDocRef.get();
      } catch (e) {
        print('⚠️  Error reading existing metadata for "$collection": $e');
        doc = null;
      }

      if (doc == null || !doc.exists) {
        // Create new metadata document
        final data = {
          ...metadata,
          'version': '1.0.0',
          'createdBy': currentUser.uid,
          'createdByEmail': currentUser.email ?? 'unknown',
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        };
        
        await metadataDocRef.set(data);
        
        // Verify it was created
        final verifyDoc = await metadataDocRef.get();
        if (verifyDoc.exists) {
          print('✅ Collection "$collection" initialized - Document ID: _metadata');
          print('   Document data keys: ${verifyDoc.data()?.keys.toList()}');
        } else {
          throw Exception('Document was not created - verification failed');
        }
      } else {
        // Update existing metadata document
        await metadataDocRef.update({
          ...metadata,
          'version': '1.0.0',
          'updatedBy': currentUser.uid,
          'updatedByEmail': currentUser.email ?? 'unknown',
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('ℹ️  Collection "$collection" metadata updated');
      }
      
      // Verify collection is accessible
      try {
        final testQuery = await _firestore.collection(collection).limit(1).get();
        print('   ✅ Collection "$collection" is accessible (${testQuery.docs.length} document(s))');
      } catch (e) {
        print('   ⚠️  Warning: Collection "$collection" may not be accessible: $e');
      }
    } on FirebaseException catch (e) {
      print('❌ Firebase error initializing collection "$collection": ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Check Firestore security rules. Make sure you are authenticated.');
      }
      rethrow;
    } catch (e) {
      print('❌ Error initializing collection "$collection": $e');
      // Continue with other collections even if one fails, but log the error
      throw Exception('Failed to initialize collection "$collection": $e');
    }
  }

  /// Delete metadata documents from all collections (cleanup)
  static Future<void> cleanupMetadata() async {
    try {
      final collections = [
        'births',
        'deaths',
        'users',
        'audit_logs',
        'notifications',
        'backups',
      ];

      for (final collection in collections) {
        try {
          await _firestore.collection(collection).doc('_metadata').delete();
          print('✅ Removed metadata from "$collection"');
        } catch (e) {
          print('⚠️  Error removing metadata from "$collection": $e');
        }
      }
    } catch (e) {
      print('❌ Error cleaning up metadata: $e');
    }
  }

  /// Check if collections are initialized
  static Future<Map<String, bool>> checkCollectionsStatus() async {
    final collections = [
      'births',
      'deaths',
      'users',
      'audit_logs',
      'notifications',
      'backups',
    ];

    final status = <String, bool>{};

    for (final collection in collections) {
      try {
        final metadataDoc = await _firestore
            .collection(collection)
            .doc('_metadata')
            .get();
        status[collection] = metadataDoc.exists;
      } catch (e) {
        status[collection] = false;
      }
    }

    return status;
  }
}

