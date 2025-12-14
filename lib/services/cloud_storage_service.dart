import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to handle cloud storage operations using Firebase Storage
class CloudStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get storage reference path for user files
  static String _getUserStoragePath() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return 'users/${user.uid}';
  }

  /// Upload a document file to cloud storage
  /// Returns the cloud storage URL
  static Future<String> uploadDocument({
    required File localFile,
    required String recordId,
    required String documentType, // 'father_id', 'mother_id', 'photo'
  }) async {
    try {
      if (!await localFile.exists()) {
        throw Exception('Local file does not exist: ${localFile.path}');
      }

      final userPath = _getUserStoragePath();
      final extension = localFile.path.split('.').last;
      final fileName = '${recordId}_${documentType}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final cloudPath = '$userPath/documents/$fileName';

      // Create reference
      final ref = _storage.ref().child(cloudPath);

      // Upload file
      final uploadTask = ref.putFile(localFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading document to cloud: $e');
    }
  }

  /// Upload a photo to cloud storage
  /// Returns the cloud storage URL
  static Future<String> uploadPhoto({
    required File localFile,
    required String recordId,
  }) async {
    return uploadDocument(
      localFile: localFile,
      recordId: recordId,
      documentType: 'photo',
    );
  }

  /// Download a file from cloud storage to local path
  static Future<File> downloadFile({
    required String cloudUrl,
    required String localPath,
  }) async {
    try {
      final ref = _storage.refFromURL(cloudUrl);
      final localFile = File(localPath);
      
      // Create parent directory if it doesn't exist
      await localFile.parent.create(recursive: true);
      
      // Download file
      await ref.writeToFile(localFile);
      
      return localFile;
    } catch (e) {
      throw Exception('Error downloading file from cloud: $e');
    }
  }

  /// Delete a file from cloud storage
  static Future<void> deleteFile(String cloudUrl) async {
    try {
      final ref = _storage.refFromURL(cloudUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Error deleting file from cloud: $e');
    }
  }

  /// Check if a file exists in cloud storage
  static Future<bool> fileExists(String cloudUrl) async {
    try {
      final ref = _storage.refFromURL(cloudUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get file metadata from cloud storage
  static Future<Map<String, dynamic>?> getFileMetadata(String cloudUrl) async {
    try {
      final ref = _storage.refFromURL(cloudUrl);
      final metadata = await ref.getMetadata();
      
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated?.millisecondsSinceEpoch,
        'updated': metadata.updated?.millisecondsSinceEpoch,
      };
    } catch (e) {
      return null;
    }
  }

  /// List all documents for a user
  static Future<List<String>> listUserDocuments() async {
    try {
      final userPath = _getUserStoragePath();
      final ref = _storage.ref().child('$userPath/documents');
      final listResult = await ref.listAll();
      
      final urls = <String>[];
      for (final item in listResult.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw Exception('Error listing user documents: $e');
    }
  }

  /// Get storage usage for current user (in bytes)
  static Future<int> getUserStorageUsage() async {
    try {
      final documents = await listUserDocuments();
      int totalSize = 0;
      
      for (final url in documents) {
        final metadata = await getFileMetadata(url);
        if (metadata != null && metadata['size'] != null) {
          totalSize += metadata['size'] as int;
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}

