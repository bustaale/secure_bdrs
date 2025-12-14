import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/abn_application.dart';
import '../services/firebase_service.dart';

class ABNProvider extends ChangeNotifier {
  final List<ABNApplication> _applications = [];
  bool _isLoading = false;
  String? _error;
  bool _useFirebase = false;

  List<ABNApplication> get applications => List.unmodifiable(_applications);
  List<ABNApplication> get activeApplications => 
      _applications.where((app) => !app.isArchived && app.status != 'archived').toList();
  List<ABNApplication> get archivedApplications => 
      _applications.where((app) => app.isArchived || app.status == 'archived').toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  ABNProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _loadFromLocal();
    } catch (e) {
      print('Error initializing ABN Provider: $e');
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final applicationsJson = prefs.getString('abn_applications') ?? '[]';
      final applicationsList = json.decode(applicationsJson) as List<dynamic>;
      _applications.clear();
      _applications.addAll(
        applicationsList.map((jsonItem) {
          if (jsonItem is Map<String, dynamic>) {
            return ABNApplication.fromMap(jsonItem);
          }
          return ABNApplication.fromMap(Map<String, dynamic>.from(jsonItem as Map));
        }).toList(),
      );
      notifyListeners();
    } catch (e) {
      print('Error loading ABN applications from local storage: $e');
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final applicationsJson = json.encode(
        _applications.map((app) => app.toMap()).toList(),
      );
      await prefs.setString('abn_applications', applicationsJson);
    } catch (e) {
      print('Error saving ABN applications to local storage: $e');
    }
  }

  // Create ABN Application
  Future<String> createABNApplication({
    required String birthRecordId,
    required String applicantName,
    required String applicantId,
    required String applicantPhone,
    required String applicantEmail,
    required String relationshipToChild,
    double? applicationFee,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final applicationNumber = 'ABN-${DateTime.now().millisecondsSinceEpoch}';
      final application = ABNApplication(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        birthRecordId: birthRecordId,
        applicationNumber: applicationNumber,
        applicationDate: DateTime.now(),
        applicantName: applicantName,
        applicantId: applicantId,
        applicantPhone: applicantPhone,
        applicantEmail: applicantEmail,
        relationshipToChild: relationshipToChild,
        status: 'submitted',
        paymentRequired: applicationFee != null && applicationFee > 0,
        applicationFee: applicationFee,
        paymentCompleted: false,
      );

      _applications.add(application);
      await _saveToLocal();
      
      // Try to save to Firebase if available
      try {
        // TODO: Implement Firebase save
      } catch (e) {
        print('Firebase save failed: $e');
      }

      _isLoading = false;
      notifyListeners();
      return application.id;
    } catch (e) {
      _error = 'Error creating ABN application: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Archive ABN Application
  Future<void> archiveABNApplication({
    required String applicationId,
    required String archivedBy,
    String? archiveReason,
  }) async {
    try {
      final index = _applications.indexWhere((app) => app.id == applicationId);
      if (index == -1) return;

      final existing = _applications[index];
      final updated = existing.copyWith(
        isArchived: true,
        archivedDate: DateTime.now(),
        archivedBy: archivedBy,
        archiveReason: archiveReason,
        status: 'archived',
      );

      _applications[index] = updated;
      await _saveToLocal();
      notifyListeners();
    } catch (e) {
      _error = 'Error archiving ABN application: $e';
      notifyListeners();
    }
  }

  // Update ABN Application
  Future<void> updateABNApplication(ABNApplication application) async {
    try {
      final index = _applications.indexWhere((app) => app.id == application.id);
      if (index == -1) return;

      _applications[index] = application;
      await _saveToLocal();
      notifyListeners();
    } catch (e) {
      _error = 'Error updating ABN application: $e';
      notifyListeners();
    }
  }

  // Get ABN Application by ID
  ABNApplication? getABNApplicationById(String id) {
    try {
      return _applications.firstWhere((app) => app.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get ABN Applications by Birth Record ID
  List<ABNApplication> getABNApplicationsByBirthRecordId(String birthRecordId) {
    return _applications.where((app) => app.birthRecordId == birthRecordId).toList();
  }

  // Mark payment as completed
  Future<void> markPaymentCompleted({
    required String applicationId,
    required String paymentReference,
    DateTime? paymentDate,
  }) async {
    try {
      final index = _applications.indexWhere((app) => app.id == applicationId);
      if (index == -1) return;

      final existing = _applications[index];
      final updated = existing.copyWith(
        paymentCompleted: true,
        paymentDate: paymentDate ?? DateTime.now(),
        paymentReference: paymentReference,
      );

      _applications[index] = updated;
      await _saveToLocal();
      notifyListeners();
    } catch (e) {
      _error = 'Error updating payment status: $e';
      notifyListeners();
    }
  }

  // Approve ABN Application
  Future<void> approveABNApplication({
    required String applicationId,
    required String approvedBy,
    String? reviewNotes,
  }) async {
    try {
      final index = _applications.indexWhere((app) => app.id == applicationId);
      if (index == -1) return;

      final existing = _applications[index];
      final updated = existing.copyWith(
        status: 'approved',
        reviewedBy: approvedBy,
        reviewedAt: DateTime.now(),
        reviewNotes: reviewNotes,
      );

      _applications[index] = updated;
      await _saveToLocal();
      notifyListeners();
    } catch (e) {
      _error = 'Error approving ABN application: $e';
      notifyListeners();
    }
  }

  // Reject ABN Application
  Future<void> rejectABNApplication({
    required String applicationId,
    required String rejectedBy,
    String? rejectionReason,
  }) async {
    try {
      final index = _applications.indexWhere((app) => app.id == applicationId);
      if (index == -1) return;

      final existing = _applications[index];
      final updated = existing.copyWith(
        status: 'rejected',
        reviewedBy: rejectedBy,
        reviewedAt: DateTime.now(),
        reviewNotes: rejectionReason,
      );

      _applications[index] = updated;
      await _saveToLocal();
      notifyListeners();
    } catch (e) {
      _error = 'Error rejecting ABN application: $e';
      notifyListeners();
    }
  }

  // Complete certificate application
  Future<void> completeCertificateApplication({
    required String applicationId,
    String? certificateNumber,
  }) async {
    try {
      final index = _applications.indexWhere((app) => app.id == applicationId);
      if (index == -1) return;

      final existing = _applications[index];
      final updated = existing.copyWith(
        certificateApplicationCompleted: true,
        certificateApplicationDate: DateTime.now(),
        certificateNumber: certificateNumber,
      );

      _applications[index] = updated;
      await _saveToLocal();
      notifyListeners();
    } catch (e) {
      _error = 'Error completing certificate application: $e';
      notifyListeners();
    }
  }
}

