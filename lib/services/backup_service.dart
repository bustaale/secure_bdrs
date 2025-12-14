import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/birth_record.dart';
import '../models/death_record.dart';
import '../services/firebase_service.dart';
import '../services/audit_log_service.dart';

class BackupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _lastBackupKey = 'last_backup_timestamp';
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';

  // Create backup
  static Future<Map<String, dynamic>> createBackup() async {
    try {
      // Get all records
      final births = await FirebaseService.getBirthRecords();
      final deaths = await FirebaseService.getDeathRecords();

      final backup = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'births': births.map((b) => b.toMap()).toList(),
        'deaths': deaths.map((d) => d.toMap()).toList(),
      };

      // Log backup creation
      await AuditLogService.logAction(
        'Backup created',
        metadata: {
          'birthCount': births.length,
          'deathCount': deaths.length,
        },
      );

      return backup;
    } catch (e) {
      throw Exception('Error creating backup: $e');
    }
  }

  // Save backup to file
  static Future<File> saveBackupToFile(Map<String, dynamic> backup) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}/backup_$timestamp.json');
      
      await file.writeAsString(jsonEncode(backup));
      return file;
    } catch (e) {
      throw Exception('Error saving backup to file: $e');
    }
  }

  // Restore from backup
  static Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    try {
      // Restore births
      if (backup['births'] != null) {
        final birthsList = (backup['births'] as List<dynamic>);
        final births = birthsList
            .map((b) {
              if (b is Map<String, dynamic>) {
                return BirthRecord.fromMap(b);
              }
              return BirthRecord.fromMap(Map<String, dynamic>.from(b as Map));
            })
            .toList();

        for (final birth in births) {
          await FirebaseService.addBirthRecord(birth);
        }
      }

      // Restore deaths
      if (backup['deaths'] != null) {
        final deathsList = (backup['deaths'] as List<dynamic>);
        final deaths = deathsList
            .map((d) {
              if (d is Map<String, dynamic>) {
                return DeathRecord.fromMap(d);
              }
              return DeathRecord.fromMap(Map<String, dynamic>.from(d as Map));
            })
            .toList();

        for (final death in deaths) {
          await FirebaseService.addDeathRecord(death);
        }
      }

      // Log restore
      await AuditLogService.logAction(
        'Backup restored',
        metadata: {
          'birthCount': backup['births']?.length ?? 0,
          'deathCount': backup['deaths']?.length ?? 0,
        },
      );
    } catch (e) {
      throw Exception('Error restoring backup: $e');
    }
  }

  // Restore from file
  static Future<void> restoreFromFile(File file) async {
    try {
      final content = await file.readAsString();
      final backup = jsonDecode(content) as Map<String, dynamic>;
      await restoreFromBackup(backup);
    } catch (e) {
      throw Exception('Error restoring from file: $e');
    }
  }

  // Get backup from Firebase Storage (if implemented)
  static Future<Map<String, dynamic>?> getBackupFromCloud(String backupId) async {
    try {
      final doc = await _firestore.collection('backups').doc(backupId).get();
      if (doc.exists) {
        final data = doc.data();
        return data != null ? Map<String, dynamic>.from(data as Map) : null;
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching backup from cloud: $e');
    }
  }

  // Save backup to Firebase Storage
  static Future<String> saveBackupToCloud(Map<String, dynamic> backup) async {
    try {
      final backupId = _firestore.collection('backups').doc().id;
      final backupData = Map<String, dynamic>.from(backup);
      backupData['createdAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('backups').doc(backupId).set(backupData);
      return backupId;
    } catch (e) {
      throw Exception('Error saving backup to cloud: $e');
    }
  }

  // Enable/Disable automatic backups
  static Future<void> setAutoBackupEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoBackupEnabledKey, enabled);
    } catch (e) {
      throw Exception('Error setting auto backup: $e');
    }
  }

  // Check if auto backup is enabled
  static Future<bool> isAutoBackupEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoBackupEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get last backup timestamp
  static Future<DateTime?> getLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastBackupKey);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save last backup timestamp
  static Future<void> _saveLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Silent fail
    }
  }

  // Create and save backup (with timestamp tracking)
  static Future<Map<String, dynamic>> createAndSaveBackup({bool saveToCloud = false}) async {
    try {
      final backup = await createBackup();
      await _saveLastBackupTime();
      
      if (saveToCloud) {
        await saveBackupToCloud(backup);
      }
      
      return backup;
    } catch (e) {
      throw Exception('Error creating and saving backup: $e');
    }
  }

  // List all cloud backups
  static Future<List<Map<String, dynamic>>> listCloudBackups() async {
    try {
      final snapshot = await _firestore
          .collection('backups')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'timestamp': data['timestamp'],
          'createdAt': data['createdAt'],
          'birthCount': (data['births'] as List?)?.length ?? 0,
          'deathCount': (data['deaths'] as List?)?.length ?? 0,
        };
      }).toList();
    } catch (e) {
      throw Exception('Error listing cloud backups: $e');
    }
  }

  // Get list of local backup files
  static Future<List<File>> getLocalBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .whereType<File>()
          .where((file) => file.path.contains('backup_'))
          .toList();
      
      // Sort by modification time (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) {
      throw Exception('Error getting local backup files: $e');
    }
  }
}

