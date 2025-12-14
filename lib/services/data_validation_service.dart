import '../models/birth_record.dart';
import '../models/death_record.dart';

/// Validation Result Model
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  String get errorMessage => errors.join('\n');
  String get warningMessage => warnings.join('\n');
}

/// Data Validation Service
/// Validates correctness and accuracy of birth and death records
class DataValidationService {
  // Kenyan ID Number Validation (8 digits)
  static bool isValidKenyanId(String? id) {
    if (id == null || id.isEmpty) return false;
    // Remove spaces and check if it's 8 digits
    final cleaned = id.replaceAll(' ', '').replaceAll('-', '');
    return RegExp(r'^\d{8}$').hasMatch(cleaned);
  }

  // Phone Number Validation (Kenyan format: +254 or 0XXXXXXXXX)
  static bool isValidKenyanPhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final cleaned = phone.replaceAll(' ', '').replaceAll('-', '');
    // Kenyan phone: +254XXXXXXXXX or 0XXXXXXXXX (10 digits)
    return RegExp(r'^(\+254|0)[1-9]\d{8}$').hasMatch(cleaned);
  }

  // Email Validation
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  // Name Validation (at least 2 characters, letters only)
  static bool isValidName(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    return RegExp(r'^[a-zA-Z\s]{2,}$').hasMatch(name.trim());
  }

  // Date Validation (not in future)
  static bool isValidDate(DateTime? date, {bool allowFuture = false}) {
    if (date == null) return false;
    if (!allowFuture && date.isAfter(DateTime.now())) return false;
    // Check if date is not too old (e.g., more than 150 years ago for birth)
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 365 * 150)))) return false;
    return true;
  }

  // Age Validation (0-150 years)
  static bool isValidAge(int? age) {
    if (age == null) return false;
    return age >= 0 && age <= 150;
  }

  // Registration Number Validation (format: CS/YYYY/XXXXX)
  static bool isValidRegistrationNumber(String? regNumber) {
    if (regNumber == null || regNumber.isEmpty) return false;
    // Format: CS/2023/50350 or similar
    return RegExp(r'^[A-Z]{2,}\/\d{4}\/\d{4,}$').hasMatch(regNumber.trim().toUpperCase());
  }

  /// Validate Birth Record
  static ValidationResult validateBirthRecord(BirthRecord record) {
    final errors = <String>[];
    final warnings = <String>[];

    // Child Name Validation
    if (!isValidName(record.childName)) {
      errors.add('Child name is required and must be at least 2 characters');
    }

    // Date of Birth Validation
    if (!isValidDate(record.dateOfBirth, allowFuture: false)) {
      errors.add('Date of birth is invalid or cannot be in the future');
    }

    // Place of Birth Validation
    if (record.placeOfBirth.trim().isEmpty) {
      errors.add('Place of birth is required');
    }

    // Gender Validation
    if (record.gender.trim().isEmpty || !['Male', 'Female', 'Other'].contains(record.gender)) {
      errors.add('Gender must be Male, Female, or Other');
    }

    // Father Information Validation
    if (!isValidName(record.fatherName)) {
      errors.add('Father name is required and must be valid');
    }
    
    if (record.fatherNationalId.isNotEmpty && !isValidKenyanId(record.fatherNationalId)) {
      errors.add('Father National ID must be 8 digits');
    }

    if (record.fatherPhone.isNotEmpty && !isValidKenyanPhone(record.fatherPhone)) {
      errors.add('Father phone number is invalid (use format: +254XXXXXXXXX or 0XXXXXXXXX)');
    }

    if (record.fatherEmail.isNotEmpty && !isValidEmail(record.fatherEmail)) {
      errors.add('Father email address is invalid');
    }

    // Mother Information Validation
    if (!isValidName(record.motherName)) {
      errors.add('Mother name is required and must be valid');
    }
    
    if (record.motherNationalId.isNotEmpty && !isValidKenyanId(record.motherNationalId)) {
      errors.add('Mother National ID must be 8 digits');
    }

    if (record.motherPhone.isNotEmpty && !isValidKenyanPhone(record.motherPhone)) {
      errors.add('Mother phone number is invalid (use format: +254XXXXXXXXX or 0XXXXXXXXX)');
    }

    if (record.motherEmail.isNotEmpty && !isValidEmail(record.motherEmail)) {
      errors.add('Mother email address is invalid');
    }

    // Registration Number Validation
    if (record.registrationNumber.isNotEmpty && !isValidRegistrationNumber(record.registrationNumber)) {
      warnings.add('Registration number format may be incorrect (expected format: CS/YYYY/XXXXX)');
    }

    // Warnings for missing optional fields
    if (record.fatherNationalId.isEmpty) {
      warnings.add('Father National ID is recommended for official records');
    }
    if (record.motherNationalId.isEmpty) {
      warnings.add('Mother National ID is recommended for official records');
    }
    if (record.fatherPhone.isEmpty && record.fatherEmail.isEmpty) {
      warnings.add('At least one contact method for father is recommended');
    }
    if (record.motherPhone.isEmpty && record.motherEmail.isEmpty) {
      warnings.add('At least one contact method for mother is recommended');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate Death Record
  static ValidationResult validateDeathRecord(DeathRecord record) {
    final errors = <String>[];
    final warnings = <String>[];

    // Name Validation
    if (!isValidName(record.name)) {
      errors.add('Deceased name is required and must be at least 2 characters');
    }

    // Date of Death Validation
    if (!isValidDate(record.dateOfDeath, allowFuture: false)) {
      errors.add('Date of death is invalid or cannot be in the future');
    }

    // Place of Death Validation
    if (record.placeOfDeath.trim().isEmpty) {
      errors.add('Place of death is required');
    }

    // Cause of Death Validation
    if (record.cause.trim().isEmpty) {
      errors.add('Cause of death is required');
    }

    // Registration Number Validation
    if (record.registrationNumber.isNotEmpty && !isValidRegistrationNumber(record.registrationNumber)) {
      warnings.add('Registration number format may be incorrect (expected format: CS/YYYY/XXXXX)');
    }

    // ID Number Validation
    if (record.idNumber != null && record.idNumber!.isNotEmpty && !isValidKenyanId(record.idNumber)) {
      errors.add('ID Number must be 8 digits');
    }

    // Age Validation
    if (record.age != null && !isValidAge(record.age)) {
      errors.add('Age must be between 0 and 150 years');
    }

    // Gender Validation
    if (record.gender != null && record.gender!.isNotEmpty) {
      if (!['Male', 'Female', 'Other'].contains(record.gender)) {
        errors.add('Gender must be Male, Female, or Other');
      }
    }

    // Next of Kin Validation
    if (record.familyName != null && record.familyName!.isNotEmpty) {
      if (!isValidName(record.familyName)) {
        errors.add('Next of kin name is invalid');
      }
    }

    if (record.familyPhone != null && record.familyPhone!.isNotEmpty) {
      if (!isValidKenyanPhone(record.familyPhone)) {
        errors.add('Next of kin phone number is invalid (use format: +254XXXXXXXXX or 0XXXXXXXXX)');
      }
    }

    // Warnings
    if (record.idNumber == null || record.idNumber!.isEmpty) {
      warnings.add('ID Number is recommended for official records');
    }
    if (record.familyName == null || record.familyName!.isEmpty) {
      warnings.add('Next of kin information is recommended');
    }
    if (record.hospital == null || record.hospital!.isEmpty) {
      warnings.add('Hospital information is recommended if death occurred in hospital');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate Complete Record Before Submission
  /// Returns true if record is valid and ready for government submission
  static ValidationResult validateForGovernmentSubmission(dynamic record) {
    if (record is BirthRecord) {
      final result = validateBirthRecord(record);
      // Additional checks for government submission
      if (result.isValid) {
        final govErrors = <String>[];
        
        // Mandatory fields for government
        if (record.fatherNationalId.isEmpty) {
          govErrors.add('Father National ID is mandatory for government submission');
        }
        if (record.motherNationalId.isEmpty) {
          govErrors.add('Mother National ID is mandatory for government submission');
        }
        if (record.registrationNumber.isEmpty) {
          govErrors.add('Registration number is mandatory for government submission');
        }
        
        if (govErrors.isNotEmpty) {
          return ValidationResult(
            isValid: false,
            errors: [...result.errors, ...govErrors],
            warnings: result.warnings,
          );
        }
      }
      return result;
    } else if (record is DeathRecord) {
      final result = validateDeathRecord(record);
      // Additional checks for government submission
      if (result.isValid) {
        final govErrors = <String>[];
        
        // Mandatory fields for government
        if (record.idNumber == null || record.idNumber!.isEmpty) {
          govErrors.add('ID Number is mandatory for government submission');
        }
        if (record.registrationNumber.isEmpty) {
          govErrors.add('Registration number is mandatory for government submission');
        }
        
        if (govErrors.isNotEmpty) {
          return ValidationResult(
            isValid: false,
            errors: [...result.errors, ...govErrors],
            warnings: result.warnings,
          );
        }
      }
      return result;
    }
    
    return ValidationResult(
      isValid: false,
      errors: ['Unknown record type'],
    );
  }
}

