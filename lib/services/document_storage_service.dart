import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_storage_service.dart';

/// Service to handle document storage in a permanent directory
/// This ensures files are not deleted by the system cache cleanup
/// Also supports cloud storage synchronization
class DocumentStorageService {
  static const String _documentsFolder = 'birth_documents';
  static const String _photosFolder = 'birth_photos';
  static const String _cloudSyncEnabledKey = 'cloud_sync_enabled';
  
  /// Check if cloud sync is enabled
  static Future<bool> isCloudSyncEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_cloudSyncEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Enable/disable cloud sync
  static Future<void> setCloudSyncEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cloudSyncEnabledKey, enabled);
    } catch (e) {
      // Silent fail
    }
  }
  
  /// Get the documents directory path
  static Future<Directory> _getDocumentsDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final documentsDir = Directory('${appDocDir.path}/$_documentsFolder');
    if (!await documentsDir.exists()) {
      await documentsDir.create(recursive: true);
    }
    return documentsDir;
  }
  
  /// Get the photos directory path
  static Future<Directory> _getPhotosDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDocDir.path}/$_photosFolder');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir;
  }
  
  /// Save a document file to permanent storage
  /// Returns the permanent path of the saved file
  /// Optionally syncs to cloud if cloud sync is enabled
  static Future<String> saveDocument({
    required File sourceFile,
    required String recordId,
    required String documentType, // e.g., 'father_id', 'mother_id'
    bool syncToCloud = true,
  }) async {
    try {
      // Check if source file exists
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: ${sourceFile.path}');
      }
      
      // Get destination directory
      final documentsDir = await _getDocumentsDirectory();
      
      // Generate unique filename: recordId_documentType_timestamp_uuid.ext
      final extension = sourceFile.path.split('.').last;
      final uuid = const Uuid().v4().substring(0, 8);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${recordId}_${documentType}_$timestamp$uuid.$extension';
      
      // Create destination file
      final destinationFile = File('${documentsDir.path}/$filename');
      
      // Copy file to permanent location
      await sourceFile.copy(destinationFile.path);
      
      // Sync to cloud if enabled
      if (syncToCloud && await isCloudSyncEnabled()) {
        try {
          await CloudStorageService.uploadDocument(
            localFile: destinationFile,
            recordId: recordId,
            documentType: documentType,
          );
        } catch (e) {
          // Log error but don't fail the save operation
          print('⚠️ Cloud sync failed (file saved locally): $e');
        }
      }
      
      // Return the permanent path
      return destinationFile.path;
    } catch (e) {
      throw Exception('Error saving document: $e');
    }
  }
  
  /// Save a photo file to permanent storage
  /// Returns the permanent path of the saved file
  /// Optionally syncs to cloud if cloud sync is enabled
  static Future<String> savePhoto({
    required File sourceFile,
    required String recordId,
    bool syncToCloud = true,
  }) async {
    try {
      // Check if source file exists
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: ${sourceFile.path}');
      }
      
      // Get destination directory
      final photosDir = await _getPhotosDirectory();
      
      // Generate unique filename: recordId_photo_timestamp_uuid.ext
      final extension = sourceFile.path.split('.').last;
      final uuid = const Uuid().v4().substring(0, 8);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${recordId}_photo_$timestamp$uuid.$extension';
      
      // Create destination file
      final destinationFile = File('${photosDir.path}/$filename');
      
      // Copy file to permanent location
      await sourceFile.copy(destinationFile.path);
      
      // Sync to cloud if enabled
      if (syncToCloud && await isCloudSyncEnabled()) {
        try {
          await CloudStorageService.uploadPhoto(
            localFile: destinationFile,
            recordId: recordId,
          );
        } catch (e) {
          // Log error but don't fail the save operation
          print('⚠️ Cloud sync failed (photo saved locally): $e');
        }
      }
      
      // Return the permanent path
      return destinationFile.path;
    } catch (e) {
      throw Exception('Error saving photo: $e');
    }
  }
  
  /// Check if a file exists at the given path
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
  
  /// Delete a document file
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
  
  /// Get file size in bytes
  static Future<int?> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

