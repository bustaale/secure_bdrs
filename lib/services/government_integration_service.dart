import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/birth_record.dart';
import '../models/death_record.dart';
import '../services/data_validation_service.dart';
import '../services/security_service.dart';
import '../constants.dart';

/// Government Integration Service
/// Handles sending validated birth and death records to government systems
class GovernmentIntegrationService {
  static const String _governmentApiUrl = "https://api.bdrs.gov.ke"; // Government API endpoint
  static const String _apiVersion = "/v1";
  
  /// Submit Birth Record to Government
  static Future<GovernmentSubmissionResult> submitBirthRecord(
    BirthRecord record,
    String userId,
    String userRole,
  ) async {
    try {
      // 1. Validate record before submission
      final validationResult = DataValidationService.validateForGovernmentSubmission(record);
      if (!validationResult.isValid) {
        return GovernmentSubmissionResult(
          success: false,
          message: 'Validation failed: ${validationResult.errorMessage}',
          errors: validationResult.errors,
        );
      }

      // 2. Check user permissions
      if (!SecurityService.canSubmitToGovernment(userRole)) {
        return GovernmentSubmissionResult(
          success: false,
          message: 'You do not have permission to submit records to government',
          errors: ['Insufficient permissions'],
        );
      }

      // 3. Record security event
      await SecurityService.recordSecurityEvent('government_submission_birth', userId);

      // 4. Prepare data for government API
      final governmentData = _prepareBirthRecordForGovernment(record);

      // 5. Send to government API
      final response = await _sendToGovernmentAPI(
        endpoint: '/births',
        data: governmentData,
        userId: userId,
      );

      if (response['success'] == true) {
        return GovernmentSubmissionResult(
          success: true,
          message: 'Birth record successfully submitted to government',
          governmentReference: response['reference_number'],
          submissionId: response['submission_id'],
        );
      } else {
        return GovernmentSubmissionResult(
          success: false,
          message: response['message'] ?? 'Failed to submit to government',
          errors: response['errors'] ?? ['Unknown error'],
        );
      }
    } catch (e) {
      return GovernmentSubmissionResult(
        success: false,
        message: 'Error submitting birth record: $e',
        errors: [e.toString()],
      );
    }
  }

  /// Submit Death Record to Government
  static Future<GovernmentSubmissionResult> submitDeathRecord(
    DeathRecord record,
    String userId,
    String userRole,
  ) async {
    try {
      // 1. Validate record before submission
      final validationResult = DataValidationService.validateForGovernmentSubmission(record);
      if (!validationResult.isValid) {
        return GovernmentSubmissionResult(
          success: false,
          message: 'Validation failed: ${validationResult.errorMessage}',
          errors: validationResult.errors,
        );
      }

      // 2. Check user permissions
      if (!SecurityService.canSubmitToGovernment(userRole)) {
        return GovernmentSubmissionResult(
          success: false,
          message: 'You do not have permission to submit records to government',
          errors: ['Insufficient permissions'],
        );
      }

      // 3. Record security event
      await SecurityService.recordSecurityEvent('government_submission_death', userId);

      // 4. Prepare data for government API
      final governmentData = _prepareDeathRecordForGovernment(record);

      // 5. Send to government API
      final response = await _sendToGovernmentAPI(
        endpoint: '/deaths',
        data: governmentData,
        userId: userId,
      );

      if (response['success'] == true) {
        return GovernmentSubmissionResult(
          success: true,
          message: 'Death record successfully submitted to government',
          governmentReference: response['reference_number'],
          submissionId: response['submission_id'],
        );
      } else {
        return GovernmentSubmissionResult(
          success: false,
          message: response['message'] ?? 'Failed to submit to government',
          errors: response['errors'] ?? ['Unknown error'],
        );
      }
    } catch (e) {
      return GovernmentSubmissionResult(
        success: false,
        message: 'Error submitting death record: $e',
        errors: [e.toString()],
      );
    }
  }

  /// Prepare Birth Record Data for Government API
  static Map<String, dynamic> _prepareBirthRecordForGovernment(BirthRecord record) {
    return {
      'record_id': record.id,
      'registration_number': record.registrationNumber,
      'child_name': record.childName,
      'gender': record.gender,
      'date_of_birth': record.dateOfBirth.toIso8601String(),
      'place_of_birth': record.placeOfBirth,
      'born_outside_region': record.bornOutsideRegion,
      'father': {
        'name': record.fatherName,
        'national_id': record.fatherNationalId,
        'phone': record.fatherPhone,
        'email': record.fatherEmail,
        'citizenship': record.fatherCitizenship,
      },
      'mother': {
        'name': record.motherName,
        'national_id': record.motherNationalId,
        'phone': record.motherPhone,
        'email': record.motherEmail,
        'citizenship': record.motherCitizenship,
      },
      'submission_timestamp': DateTime.now().toIso8601String(),
      'data_hash': SecurityService.hashData(record.id + record.registrationNumber),
    };
  }

  /// Prepare Death Record Data for Government API
  static Map<String, dynamic> _prepareDeathRecordForGovernment(DeathRecord record) {
    return {
      'record_id': record.id,
      'registration_number': record.registrationNumber,
      'name': record.name,
      'id_number': record.idNumber,
      'gender': record.gender,
      'age': record.age,
      'date_of_death': record.dateOfDeath.toIso8601String(),
      'place_of_death': record.placeOfDeath,
      'hospital': record.hospital,
      'cause_of_death': record.cause,
      'next_of_kin': {
        'name': record.familyName,
        'relation': record.familyRelation,
        'phone': record.familyPhone,
      },
      'submission_timestamp': DateTime.now().toIso8601String(),
      'data_hash': SecurityService.hashData(record.id + record.registrationNumber),
    };
  }

  /// Send Data to Government API
  static Future<Map<String, dynamic>> _sendToGovernmentAPI({
    required String endpoint,
    required Map<String, dynamic> data,
    required String userId,
  }) async {
    try {
      final url = Uri.parse('$_governmentApiUrl$_apiVersion$endpoint');
      
      // Get authentication token (in production, use proper authentication)
      final token = await _getGovernmentAPIToken(userId);
      
      // Add security headers
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'X-User-ID': userId,
        'X-Submission-Date': DateTime.now().toIso8601String(),
        'X-Data-Hash': SecurityService.hashData(jsonEncode(data)),
      };

      // Send POST request
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - government server did not respond');
        },
      );

      // Parse response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'reference_number': responseData['reference_number'],
          'submission_id': responseData['submission_id'],
          'message': responseData['message'] ?? 'Submission successful',
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message': errorData['message'] ?? 'Government API error',
          'errors': errorData['errors'] ?? ['HTTP ${response.statusCode}'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'errors': [e.toString()],
      };
    }
  }

  /// Get Government API Token
  /// In production, implement proper OAuth2 or API key authentication
  static Future<String> _getGovernmentAPIToken(String userId) async {
    // TODO: Implement proper token retrieval
    // For now, generate a secure token
    return SecurityService.generateSecureToken();
  }

  /// Check Government API Status
  static Future<bool> checkGovernmentAPIStatus() async {
    try {
      final url = Uri.parse('$_governmentApiUrl$_apiVersion/health');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Batch Submit Records
  static Future<List<GovernmentSubmissionResult>> batchSubmitRecords({
    required List<BirthRecord>? birthRecords,
    required List<DeathRecord>? deathRecords,
    required String userId,
    required String userRole,
  }) async {
    final results = <GovernmentSubmissionResult>[];

    // Submit birth records
    if (birthRecords != null) {
      for (final record in birthRecords) {
        final result = await submitBirthRecord(record, userId, userRole);
        results.add(result);
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // Submit death records
    if (deathRecords != null) {
      for (final record in deathRecords) {
        final result = await submitDeathRecord(record, userId, userRole);
        results.add(result);
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return results;
  }
}

/// Government Submission Result
class GovernmentSubmissionResult {
  final bool success;
  final String message;
  final List<String> errors;
  final String? governmentReference;
  final String? submissionId;

  GovernmentSubmissionResult({
    required this.success,
    required this.message,
    this.errors = const [],
    this.governmentReference,
    this.submissionId,
  });

  bool get hasErrors => errors.isNotEmpty;
}

