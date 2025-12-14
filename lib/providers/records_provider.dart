import "package:flutter/material.dart";
import "dart:async";
import "dart:convert";
import "package:shared_preferences/shared_preferences.dart";
import "../models/birth_record.dart";
import "../models/death_record.dart";
import "../services/firebase_service.dart";

class RecordsProvider extends ChangeNotifier {
  final List<BirthRecord> _births = [];
  final List<DeathRecord> _deaths = [];
  bool _isLoading = false;
  String? _error;
  bool _useFirebase = false;
  bool _realtimeEnabled = false;
  DateTime? _lastSyncedAt;
  StreamSubscription<List<BirthRecord>>? _birthsSubscription;
  StreamSubscription<List<DeathRecord>>? _deathsSubscription;

  List<BirthRecord> get births => List.unmodifiable(_births.reversed);
  List<DeathRecord> get deaths => List.unmodifiable(_deaths.reversed);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get realtimeEnabled => _realtimeEnabled;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  RecordsProvider() {
    _initialize();
  }

  // Initialize and load data
  Future<void> _initialize() async {
    try {
      await _attemptCloudBootstrap();
    } catch (e) {
      print('Firebase not available, using local storage: $e');
      _useFirebase = false;
      await _loadFromLocal();
    }
  }

  Future<void> _attemptCloudBootstrap() async {
    try {
      _useFirebase = true;
      await loadBirthRecords();
      await loadDeathRecords();
      _startRealtimeListeners();
    } catch (e) {
      print('Realtime bootstrap failed: $e');
      _useFirebase = false;
      await _loadFromLocal();
      _stopRealtimeListeners();
    }
  }

  // Load from local storage (SharedPreferences)
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if data was cleared previously
      final wasCleared = prefs.getBool('data_cleared') ?? false;
      if (wasCleared) {
        // Old data was cleared, but now we want to load new data
        // Remove the cleared flag since we're starting fresh
        await prefs.remove('data_cleared');
      }
      
      // Load births (will be empty if no data exists)
      final birthsJson = prefs.getString('births') ?? '[]';
      final birthsList = json.decode(birthsJson) as List<dynamic>;
      _births.clear();
      _births.addAll(
        birthsList.map((jsonItem) {
          if (jsonItem is Map<String, dynamic>) {
            return BirthRecord.fromMap(jsonItem);
          }
          return BirthRecord.fromMap(Map<String, dynamic>.from(jsonItem as Map));
        }).toList(),
      );
      
      // Load deaths (will be empty if no data exists)
      final deathsJson = prefs.getString('deaths') ?? '[]';
      final deathsList = json.decode(deathsJson) as List<dynamic>;
      _deaths.clear();
      _deaths.addAll(
        deathsList.map((jsonItem) {
          if (jsonItem is Map<String, dynamic>) {
            return DeathRecord.fromMap(jsonItem);
          }
          return DeathRecord.fromMap(Map<String, dynamic>.from(jsonItem as Map));
        }).toList(),
      );
      
      _lastSyncedAt ??= DateTime.now();
      notifyListeners();
      print('Loaded ${_births.length} births and ${_deaths.length} deaths from storage');
    } catch (e) {
      print('Error loading from local storage: $e');
    }
  }

  void _startRealtimeListeners() {
    if (!_useFirebase) return;
    _realtimeEnabled = true;
    _birthsSubscription?.cancel();
    _deathsSubscription?.cancel();

    _birthsSubscription = FirebaseService.streamBirthRecords().listen(
      (records) {
        if (!_useFirebase) return;
        
        // Only update if we have valid records or if we're sure it's a valid update
        if (records.isNotEmpty || _births.isEmpty) {
          // Save current data to local before clearing (as backup)
          _saveToLocal();
          
          // Now update with new data
          _births.clear();
          _births.addAll(records);
          
          // Save new data to local storage
          _saveToLocal();
          
          _lastSyncedAt = DateTime.now();
          notifyListeners();
        }
      },
      onError: (error) {
        print('Firebase birth stream error: $error');
        // Don't clear data on error - keep existing data
        // Only handle failure if we have no local data
        if (_births.isEmpty) {
          _handleRealtimeFailure();
        }
      },
    );

    _deathsSubscription = FirebaseService.streamDeathRecords().listen(
      (records) {
        if (!_useFirebase) return;
        
        // Only update if we have valid records or if we're sure it's a valid update
        if (records.isNotEmpty || _deaths.isEmpty) {
          // Save current data to local before clearing (as backup)
          _saveToLocal();
          
          // Now update with new data
          _deaths.clear();
          _deaths.addAll(records);
          
          // Save new data to local storage
          _saveToLocal();
          
          _lastSyncedAt = DateTime.now();
          notifyListeners();
        }
      },
      onError: (error) {
        print('Firebase death stream error: $error');
        // Don't clear data on error - keep existing data
        // Only handle failure if we have no local data
        if (_deaths.isEmpty) {
          _handleRealtimeFailure();
        }
      },
    );
  }

  void _stopRealtimeListeners() {
    _realtimeEnabled = false;
    _birthsSubscription?.cancel();
    _deathsSubscription?.cancel();
    _birthsSubscription = null;
    _deathsSubscription = null;
  }

  void _handleRealtimeFailure() {
    _useFirebase = false;
    _stopRealtimeListeners();
    _loadFromLocal();
  }

  Future<void> retryRealtime() async {
    if (_useFirebase && _realtimeEnabled) return;
    await _attemptCloudBootstrap();
  }

  Future<void> refreshFromCloud() async {
    if (!_useFirebase) return;
    await loadBirthRecords();
    await loadDeathRecords();
    _lastSyncedAt = DateTime.now();
    notifyListeners();
  }

  // Save to local storage
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save births
      final birthsJson = json.encode(
        _births.map((record) => record.toMap()).toList(),
      );
      await prefs.setString('births', birthsJson);
      
      // Save deaths
      final deathsJson = json.encode(
        _deaths.map((record) => record.toMap()).toList(),
      );
      await prefs.setString('deaths', deathsJson);
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  // Load birth records from Firebase or local
  Future<void> loadBirthRecords() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_useFirebase) {
        try {
          final records = await FirebaseService.getBirthRecords();
          
          // Only clear and replace if we have valid records or local is empty
          if (records.isNotEmpty || _births.isEmpty) {
            // Save current data as backup before clearing
            await _saveToLocal();
            
            _births.clear();
            _births.addAll(records);
            
            // Save new data to local
            await _saveToLocal();
          }
          // If Firebase returns empty but we have local data, keep local data
        } catch (e) {
          print('Firebase error, falling back to local: $e');
          _useFirebase = false;
          await _loadFromLocal();
        }
      } else {
        await _loadFromLocal();
      }
      
      _lastSyncedAt = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading birth records: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load death records from Firebase or local
  Future<void> loadDeathRecords() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_useFirebase) {
        try {
          final records = await FirebaseService.getDeathRecords();
          
          // Only clear and replace if we have valid records or local is empty
          if (records.isNotEmpty || _deaths.isEmpty) {
            // Save current data as backup before clearing
            await _saveToLocal();
            
            _deaths.clear();
            _deaths.addAll(records);
            
            // Save new data to local
            await _saveToLocal();
          }
          // If Firebase returns empty but we have local data, keep local data
        } catch (e) {
          print('Firebase error, falling back to local: $e');
          _useFirebase = false;
          await _loadFromLocal();
        }
      } else {
        await _loadFromLocal();
      }
      
      _lastSyncedAt = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading death records: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add birth record
  Future<void> addBirth(BirthRecord b) async {
    try {
      _error = null;
      
      // Add to local list immediately for instant UI update
      _births.add(b);
      await _saveToLocal(); // Always save locally
      notifyListeners();

      // Always try to save to Firebase (even if previous attempts failed)
      try {
        await FirebaseService.addBirthRecord(b);
        print('✅ Birth record saved to Firebase: ${b.id}');
        // If save succeeds, ensure Firebase is enabled
        if (!_useFirebase) {
          _useFirebase = true;
          _startRealtimeListeners();
        }
      } catch (e) {
        print('⚠️ Firebase save failed for birth record: $e');
        print('Record saved locally only. Will retry sync later.');
        // Don't disable Firebase permanently - just log the error
        // Data is already saved locally, so it's safe
      }
    } catch (e) {
      _error = 'Error adding birth record: $e';
      notifyListeners();
    }
  }

  // Add death record
  Future<void> addDeath(DeathRecord d) async {
    try {
      _error = null;
      
      // Add to local list immediately for instant UI update
      _deaths.add(d);
      await _saveToLocal(); // Always save locally
      notifyListeners();

      // Always try to save to Firebase (even if previous attempts failed)
      try {
        await FirebaseService.addDeathRecord(d);
        print('✅ Death record saved to Firebase: ${d.id}');
        // If save succeeds, ensure Firebase is enabled
        if (!_useFirebase) {
          _useFirebase = true;
          _startRealtimeListeners();
        }
      } catch (e) {
        print('⚠️ Firebase save failed for death record: $e');
        print('Record saved locally only. Will retry sync later.');
        // Don't disable Firebase permanently - just log the error
        // Data is already saved locally, so it's safe
      }
    } catch (e) {
      _error = 'Error adding death record: $e';
      notifyListeners();
    }
  }

  // Update birth record
  Future<void> updateBirth(BirthRecord b) async {
    try {
      _error = null;
      
      // Update local list
      final index = _births.indexWhere((record) => record.id == b.id);
      if (index == -1) {
        // If record not found, add it instead
        _births.add(b);
      } else {
        _births[index] = b;
      }
      await _saveToLocal();
      notifyListeners();

      // Always try to update in Firebase (even if previous attempts failed)
      try {
        await FirebaseService.updateBirthRecord(b);
        print('✅ Birth record updated in Firebase: ${b.id}');
        // If update succeeds, ensure Firebase is enabled
        if (!_useFirebase) {
          _useFirebase = true;
          _startRealtimeListeners();
        }
      } catch (e) {
        print('⚠️ Firebase update failed for birth record: $e');
        // Don't disable Firebase - just log the error
        // Data is already saved locally
      }
    } catch (e, stackTrace) {
      print('Error updating birth record: $e');
      print('Stack trace: $stackTrace');
      _error = 'Error updating birth record: $e';
      notifyListeners();
      rethrow; // Re-throw so calling code can handle it
    }
  }

  // Update death record
  Future<void> updateDeath(DeathRecord d) async {
    try {
      _error = null;
      
      // Update local list
      final index = _deaths.indexWhere((record) => record.id == d.id);
      if (index != -1) {
        _deaths[index] = d;
      }
      await _saveToLocal();
      notifyListeners();

      // Always try to update in Firebase (even if previous attempts failed)
      try {
        await FirebaseService.updateDeathRecord(d);
        print('✅ Death record updated in Firebase: ${d.id}');
        // If update succeeds, ensure Firebase is enabled
        if (!_useFirebase) {
          _useFirebase = true;
          _startRealtimeListeners();
        }
      } catch (e) {
        print('⚠️ Firebase update failed for death record: $e');
        // Don't disable Firebase - just log the error
        // Data is already saved locally
      }
    } catch (e) {
      _error = 'Error updating death record: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopRealtimeListeners();
    super.dispose();
  }

  Future<void> markBirthCertificateStatus({
    required String recordId,
    required bool issued,
    String? issuedBy,
  }) async {
    final index = _births.indexWhere((record) => record.id == recordId);
    if (index == -1) return;

    final existing = _births[index];
    final updated = BirthRecord(
      id: existing.id,
      childName: existing.childName,
      gender: existing.gender,
      dateOfBirth: existing.dateOfBirth,
      placeOfBirth: existing.placeOfBirth,
      bornOutsideRegion: existing.bornOutsideRegion,
      declarationStatement: existing.declarationStatement,
      fatherName: existing.fatherName,
      fatherNationalId: existing.fatherNationalId,
      fatherPhone: existing.fatherPhone,
      fatherEmail: existing.fatherEmail,
      fatherCitizenship: existing.fatherCitizenship,
      motherName: existing.motherName,
      motherNationalId: existing.motherNationalId,
      motherPhone: existing.motherPhone,
      motherEmail: existing.motherEmail,
      motherCitizenship: existing.motherCitizenship,
      photoPath: existing.photoPath,
      registrationNumber: existing.registrationNumber,
      motherId: existing.motherId,
      fatherId: existing.fatherId,
      declaration: existing.declaration,
      imagePath: existing.imagePath,
      weight: existing.weight,
      height: existing.height,
      registrationDate: existing.registrationDate,
      registrar: existing.registrar,
      certificateIssued: issued,
      certificateIssuedDate: issued ? DateTime.now() : null,
      certificateIssuedBy: issued ? (issuedBy ?? 'Administrator') : null,
      fatherIdDocumentPath: existing.fatherIdDocumentPath,
      motherIdDocumentPath: existing.motherIdDocumentPath,
      approvalStatus: existing.approvalStatus,
      approvedBy: existing.approvedBy,
      approvedAt: existing.approvedAt,
      rejectionReason: existing.rejectionReason,
      requiredDocuments: existing.requiredDocuments,
      abnApplicationId: existing.abnApplicationId,
      paymentRequired: existing.paymentRequired,
      paymentCompleted: existing.paymentCompleted,
      applicationFee: existing.applicationFee,
      paymentReference: existing.paymentReference,
      certificateApplicationCompleted: existing.certificateApplicationCompleted,
      certificateApplicationDate: existing.certificateApplicationDate,
    );

    await updateBirth(updated);
  }

  Future<void> markDeathCertificateStatus({
    required String recordId,
    required bool issued,
    String? issuedBy,
  }) async {
    final index = _deaths.indexWhere((record) => record.id == recordId);
    if (index == -1) return;

    final existing = _deaths[index];
    final updated = DeathRecord(
      id: existing.id,
      name: existing.name,
      dateOfDeath: existing.dateOfDeath,
      placeOfDeath: existing.placeOfDeath,
      cause: existing.cause,
      registrationNumber: existing.registrationNumber,
      idNumber: existing.idNumber,
      hospital: existing.hospital,
      familyName: existing.familyName,
      familyRelation: existing.familyRelation,
      familyPhone: existing.familyPhone,
      gender: existing.gender,
      age: existing.age,
      certificateIssued: issued,
      certificateIssuedDate: issued ? DateTime.now() : null,
      certificateIssuedBy: issued ? (issuedBy ?? 'Administrator') : null,
    );

    await updateDeath(updated);
  }

  // Delete birth record
  Future<void> deleteBirth(String id) async {
    try {
      _error = null;
      
      // Remove from local list
      _births.removeWhere((record) => record.id == id);
      await _saveToLocal();
      notifyListeners();

      // Try to delete from Firebase if available
      if (_useFirebase) {
        try {
          await FirebaseService.deleteBirthRecord(id);
        } catch (e) {
          print('Firebase delete failed: $e');
        }
      }
    } catch (e) {
      _error = 'Error deleting birth record: $e';
      notifyListeners();
    }
  }

  // Delete death record
  Future<void> deleteDeath(String id) async {
    try {
      _error = null;
      
      // Remove from local list
      _deaths.removeWhere((record) => record.id == id);
      await _saveToLocal();
      notifyListeners();

      // Try to delete from Firebase if available
      if (_useFirebase) {
        try {
          await FirebaseService.deleteDeathRecord(id);
        } catch (e) {
          print('Firebase delete failed: $e');
        }
      }
    } catch (e) {
      _error = 'Error deleting death record: $e';
      notifyListeners();
    }
  }

  BirthRecord? findBirthById(String id) {
    try {
      return _births.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  DeathRecord? findDeathById(String id) {
    try {
      return _deaths.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // Clear all data (used when user wants to start fresh)
  Future<void> clearAllData() async {
    try {
      // Clear in-memory data
      _births.clear();
      _deaths.clear();
      
      // Clear from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('births');
      await prefs.remove('deaths');
      
      // Set flag to indicate data was cleared (prevents reloading old data on next login)
      await prefs.setBool('data_cleared', true);
      
      notifyListeners();
      print('All records data cleared successfully');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  // Force save current data to storage (used before logout)
  Future<void> forceSave() async {
    await _saveToLocal();
    print('Current data saved to storage');
  }

  // Approve birth record
  Future<void> approveBirthRecord({
    required String recordId,
    required String approvedBy,
  }) async {
    final index = _births.indexWhere((record) => record.id == recordId);
    if (index == -1) return;

    final existing = _births[index];
    final updated = BirthRecord(
      id: existing.id,
      childName: existing.childName,
      gender: existing.gender,
      dateOfBirth: existing.dateOfBirth,
      placeOfBirth: existing.placeOfBirth,
      bornOutsideRegion: existing.bornOutsideRegion,
      declarationStatement: existing.declarationStatement,
      fatherName: existing.fatherName,
      fatherNationalId: existing.fatherNationalId,
      fatherPhone: existing.fatherPhone,
      fatherEmail: existing.fatherEmail,
      fatherCitizenship: existing.fatherCitizenship,
      motherName: existing.motherName,
      motherNationalId: existing.motherNationalId,
      motherPhone: existing.motherPhone,
      motherEmail: existing.motherEmail,
      motherCitizenship: existing.motherCitizenship,
      photoPath: existing.photoPath,
      registrationNumber: existing.registrationNumber,
      motherId: existing.motherId,
      fatherId: existing.fatherId,
      declaration: existing.declaration,
      imagePath: existing.imagePath,
      weight: existing.weight,
      height: existing.height,
      registrationDate: existing.registrationDate,
      registrar: existing.registrar,
      certificateIssued: existing.certificateIssued,
      certificateIssuedDate: existing.certificateIssuedDate,
      certificateIssuedBy: existing.certificateIssuedBy,
      fatherIdDocumentPath: existing.fatherIdDocumentPath,
      motherIdDocumentPath: existing.motherIdDocumentPath,
      approvalStatus: 'approved',
      approvedBy: approvedBy,
      approvedAt: DateTime.now(),
      rejectionReason: null,
      requiredDocuments: existing.requiredDocuments,
      abnApplicationId: existing.abnApplicationId,
      paymentRequired: existing.paymentRequired,
      paymentCompleted: existing.paymentCompleted,
      applicationFee: existing.applicationFee,
      paymentReference: existing.paymentReference,
      certificateApplicationCompleted: existing.certificateApplicationCompleted,
      certificateApplicationDate: existing.certificateApplicationDate,
    );

    await updateBirth(updated);
  }

  // Reject birth record
  Future<void> rejectBirthRecord({
    required String recordId,
    required String rejectedBy,
    required String rejectionReason,
  }) async {
    final index = _births.indexWhere((record) => record.id == recordId);
    if (index == -1) return;

    final existing = _births[index];
    final updated = BirthRecord(
      id: existing.id,
      childName: existing.childName,
      gender: existing.gender,
      dateOfBirth: existing.dateOfBirth,
      placeOfBirth: existing.placeOfBirth,
      bornOutsideRegion: existing.bornOutsideRegion,
      declarationStatement: existing.declarationStatement,
      fatherName: existing.fatherName,
      fatherNationalId: existing.fatherNationalId,
      fatherPhone: existing.fatherPhone,
      fatherEmail: existing.fatherEmail,
      fatherCitizenship: existing.fatherCitizenship,
      motherName: existing.motherName,
      motherNationalId: existing.motherNationalId,
      motherPhone: existing.motherPhone,
      motherEmail: existing.motherEmail,
      motherCitizenship: existing.motherCitizenship,
      photoPath: existing.photoPath,
      registrationNumber: existing.registrationNumber,
      motherId: existing.motherId,
      fatherId: existing.fatherId,
      declaration: existing.declaration,
      imagePath: existing.imagePath,
      weight: existing.weight,
      height: existing.height,
      registrationDate: existing.registrationDate,
      registrar: existing.registrar,
      certificateIssued: existing.certificateIssued,
      certificateIssuedDate: existing.certificateIssuedDate,
      certificateIssuedBy: existing.certificateIssuedBy,
      fatherIdDocumentPath: existing.fatherIdDocumentPath,
      motherIdDocumentPath: existing.motherIdDocumentPath,
      approvalStatus: 'rejected',
      approvedBy: rejectedBy,
      approvedAt: DateTime.now(),
      rejectionReason: rejectionReason,
      requiredDocuments: existing.requiredDocuments,
      abnApplicationId: existing.abnApplicationId,
      paymentRequired: existing.paymentRequired,
      paymentCompleted: existing.paymentCompleted,
      applicationFee: existing.applicationFee,
      paymentReference: existing.paymentReference,
      certificateApplicationCompleted: existing.certificateApplicationCompleted,
      certificateApplicationDate: existing.certificateApplicationDate,
    );

    await updateBirth(updated);
  }
}
