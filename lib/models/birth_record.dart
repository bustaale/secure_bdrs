import 'package:cloud_firestore/cloud_firestore.dart';

class BirthRecord {
  final String id;
  final String childName;
  final String gender;
  final DateTime dateOfBirth;
  final String placeOfBirth;
  final bool bornOutsideRegion;
  final String declarationStatement;
  final String fatherName;
  final String fatherNationalId;
  final String fatherPhone;
  final String fatherEmail;
  final String fatherCitizenship;
  final String motherName;
  final String motherNationalId;
  final String motherPhone;
  final String motherEmail;
  final String motherCitizenship;
  final String photoPath;
  final String registrationNumber;
  final String motherId;
  final String fatherId;
  final String declaration;
  final String imagePath;
  final bool certificateIssued;
  final DateTime? certificateIssuedDate;
  final String? certificateIssuedBy;
  String? weight;
  String? height;
  DateTime? registrationDate;
  String? registrar;
  // Document upload paths
  String? fatherIdDocumentPath;
  String? motherIdDocumentPath;
  // Approval status
  String approvalStatus; // 'pending', 'approved', 'rejected'
  String? approvedBy;
  DateTime? approvedAt;
  String? rejectionReason;
  List<String> requiredDocuments; // List of required document types
  // Payment and ABN Information
  String? abnApplicationId; // Reference to ABN application
  bool paymentRequired;
  bool paymentCompleted;
  double? applicationFee;
  String? paymentReference;
  // Certificate Application
  bool certificateApplicationCompleted;
  DateTime? certificateApplicationDate;

  BirthRecord({
    required this.id,
    required this.childName,
    required this.gender,
    required this.dateOfBirth,
    required this.placeOfBirth,
    required this.bornOutsideRegion,
    required this.declarationStatement,
    required this.fatherName,
    required this.fatherNationalId,
    required this.fatherPhone,
    required this.fatherEmail,
    required this.fatherCitizenship,
    required this.motherName,
    required this.motherNationalId,
    required this.motherPhone,
    required this.motherEmail,
    required this.motherCitizenship,
    required this.photoPath,
    required this.registrationNumber,
    required this.motherId,
    required this.fatherId,
    required this.declaration,
    required this.imagePath,
    this.weight,
    this.height,
    this.registrationDate,
    this.registrar,
    this.certificateIssued = false,
    this.certificateIssuedDate,
    this.certificateIssuedBy,
    this.fatherIdDocumentPath,
    this.motherIdDocumentPath,
    this.approvalStatus = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.requiredDocuments = const ['father_id', 'mother_id'],
    this.abnApplicationId,
    this.paymentRequired = true,
    this.paymentCompleted = false,
    this.applicationFee,
    this.paymentReference,
    this.certificateApplicationCompleted = false,
    this.certificateApplicationDate,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childName': childName,
      'gender': gender,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'placeOfBirth': placeOfBirth,
      'bornOutsideRegion': bornOutsideRegion,
      'declarationStatement': declarationStatement,
      'fatherName': fatherName,
      'fatherNationalId': fatherNationalId,
      'fatherPhone': fatherPhone,
      'fatherEmail': fatherEmail,
      'fatherCitizenship': fatherCitizenship,
      'motherName': motherName,
      'motherNationalId': motherNationalId,
      'motherPhone': motherPhone,
      'motherEmail': motherEmail,
      'motherCitizenship': motherCitizenship,
      'photoPath': photoPath,
      'registrationNumber': registrationNumber,
      'motherId': motherId,
      'fatherId': fatherId,
      'declaration': declaration,
      'imagePath': imagePath,
      'weight': weight,
      'height': height,
      'registrationDate': registrationDate?.toIso8601String(),
      'registrar': registrar,
      'certificateIssued': certificateIssued,
      'certificateIssuedDate': certificateIssuedDate?.toIso8601String(),
      'certificateIssuedBy': certificateIssuedBy,
      'fatherIdDocumentPath': fatherIdDocumentPath,
      'motherIdDocumentPath': motherIdDocumentPath,
      'approvalStatus': approvalStatus,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'requiredDocuments': requiredDocuments,
      'abnApplicationId': abnApplicationId,
      'paymentRequired': paymentRequired,
      'paymentCompleted': paymentCompleted,
      'applicationFee': applicationFee,
      'paymentReference': paymentReference,
      'certificateApplicationCompleted': certificateApplicationCompleted,
      'certificateApplicationDate': certificateApplicationDate?.toIso8601String(),
    };
  }

  // Create from Map (Firebase)
  factory BirthRecord.fromMap(Map<String, dynamic> map) {
    // Handle Firestore Timestamp
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return BirthRecord(
      id: map['id'] ?? '',
      childName: map['childName'] ?? '',
      gender: map['gender'] ?? '',
      dateOfBirth: parseTimestamp(map['dateOfBirth']) ?? DateTime.now(),
      placeOfBirth: map['placeOfBirth'] ?? '',
      bornOutsideRegion: map['bornOutsideRegion'] ?? false,
      declarationStatement: map['declarationStatement'] ?? '',
      fatherName: map['fatherName'] ?? '',
      fatherNationalId: map['fatherNationalId'] ?? '',
      fatherPhone: map['fatherPhone'] ?? '',
      fatherEmail: map['fatherEmail'] ?? '',
      fatherCitizenship: map['fatherCitizenship'] ?? '',
      motherName: map['motherName'] ?? '',
      motherNationalId: map['motherNationalId'] ?? '',
      motherPhone: map['motherPhone'] ?? '',
      motherEmail: map['motherEmail'] ?? '',
      motherCitizenship: map['motherCitizenship'] ?? '',
      photoPath: map['photoPath'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      motherId: map['motherId'] ?? '',
      fatherId: map['fatherId'] ?? '',
      declaration: map['declaration'] ?? '',
      imagePath: map['imagePath'] ?? '',
      weight: map['weight'],
      height: map['height'],
      registrationDate: parseTimestamp(map['registrationDate']),
      registrar: map['registrar'],
      certificateIssued: map['certificateIssued'] ?? false,
      certificateIssuedDate: parseTimestamp(map['certificateIssuedDate']),
      certificateIssuedBy: map['certificateIssuedBy'],
      fatherIdDocumentPath: map['fatherIdDocumentPath'],
      motherIdDocumentPath: map['motherIdDocumentPath'],
      approvalStatus: map['approvalStatus'] ?? 'pending',
      approvedBy: map['approvedBy'],
      approvedAt: parseTimestamp(map['approvedAt']),
      rejectionReason: map['rejectionReason'],
      requiredDocuments: map['requiredDocuments'] != null 
          ? List<String>.from(map['requiredDocuments'])
          : ['father_id', 'mother_id'],
      abnApplicationId: map['abnApplicationId'],
      paymentRequired: map['paymentRequired'] ?? true,
      paymentCompleted: map['paymentCompleted'] ?? false,
      applicationFee: map['applicationFee']?.toDouble(),
      paymentReference: map['paymentReference'],
      certificateApplicationCompleted: map['certificateApplicationCompleted'] ?? false,
      certificateApplicationDate: parseTimestamp(map['certificateApplicationDate']),
    );
  }
}
