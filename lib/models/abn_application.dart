import 'package:cloud_firestore/cloud_firestore.dart';

/// Application for Birth Notification (ABN) Model
/// Stores birth registration applications with archiving support
class ABNApplication {
  final String id;
  final String birthRecordId; // Reference to BirthRecord
  final String applicationNumber;
  final DateTime applicationDate;
  final String applicantName;
  final String applicantId;
  final String applicantPhone;
  final String applicantEmail;
  final String relationshipToChild; // Father, Mother, Guardian, etc.
  
  // Application Status
  final String status; // 'draft', 'submitted', 'under_review', 'approved', 'rejected', 'archived'
  
  // Payment Information
  final bool paymentRequired;
  final double? applicationFee;
  final bool paymentCompleted;
  final DateTime? paymentDate;
  final String? paymentReference;
  
  // Archiving Information
  final bool isArchived;
  final DateTime? archivedDate;
  final String? archivedBy;
  final String? archiveReason;
  
  // Review Information
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  
  // Certificate Information
  final bool certificateApplicationCompleted;
  final DateTime? certificateApplicationDate;
  final String? certificateNumber;
  
  ABNApplication({
    required this.id,
    required this.birthRecordId,
    required this.applicationNumber,
    required this.applicationDate,
    required this.applicantName,
    required this.applicantId,
    required this.applicantPhone,
    required this.applicantEmail,
    required this.relationshipToChild,
    this.status = 'draft',
    this.paymentRequired = true,
    this.applicationFee,
    this.paymentCompleted = false,
    this.paymentDate,
    this.paymentReference,
    this.isArchived = false,
    this.archivedDate,
    this.archivedBy,
    this.archiveReason,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    this.certificateApplicationCompleted = false,
    this.certificateApplicationDate,
    this.certificateNumber,
  });

  // Convert to Map for Firebase/Storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'birthRecordId': birthRecordId,
      'applicationNumber': applicationNumber,
      'applicationDate': applicationDate.toIso8601String(),
      'applicantName': applicantName,
      'applicantId': applicantId,
      'applicantPhone': applicantPhone,
      'applicantEmail': applicantEmail,
      'relationshipToChild': relationshipToChild,
      'status': status,
      'paymentRequired': paymentRequired,
      'applicationFee': applicationFee,
      'paymentCompleted': paymentCompleted,
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentReference': paymentReference,
      'isArchived': isArchived,
      'archivedDate': archivedDate?.toIso8601String(),
      'archivedBy': archivedBy,
      'archiveReason': archiveReason,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewNotes': reviewNotes,
      'certificateApplicationCompleted': certificateApplicationCompleted,
      'certificateApplicationDate': certificateApplicationDate?.toIso8601String(),
      'certificateNumber': certificateNumber,
    };
  }

  // Create from Map (Firebase/Storage)
  factory ABNApplication.fromMap(Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return ABNApplication(
      id: map['id'] ?? '',
      birthRecordId: map['birthRecordId'] ?? '',
      applicationNumber: map['applicationNumber'] ?? '',
      applicationDate: parseTimestamp(map['applicationDate']) ?? DateTime.now(),
      applicantName: map['applicantName'] ?? '',
      applicantId: map['applicantId'] ?? '',
      applicantPhone: map['applicantPhone'] ?? '',
      applicantEmail: map['applicantEmail'] ?? '',
      relationshipToChild: map['relationshipToChild'] ?? '',
      status: map['status'] ?? 'draft',
      paymentRequired: map['paymentRequired'] ?? true,
      applicationFee: map['applicationFee']?.toDouble(),
      paymentCompleted: map['paymentCompleted'] ?? false,
      paymentDate: parseTimestamp(map['paymentDate']),
      paymentReference: map['paymentReference'],
      isArchived: map['isArchived'] ?? false,
      archivedDate: parseTimestamp(map['archivedDate']),
      archivedBy: map['archivedBy'],
      archiveReason: map['archiveReason'],
      reviewedBy: map['reviewedBy'],
      reviewedAt: parseTimestamp(map['reviewedAt']),
      reviewNotes: map['reviewNotes'],
      certificateApplicationCompleted: map['certificateApplicationCompleted'] ?? false,
      certificateApplicationDate: parseTimestamp(map['certificateApplicationDate']),
      certificateNumber: map['certificateNumber'],
    );
  }

  // Create a copy with updated fields
  ABNApplication copyWith({
    String? id,
    String? birthRecordId,
    String? applicationNumber,
    DateTime? applicationDate,
    String? applicantName,
    String? applicantId,
    String? applicantPhone,
    String? applicantEmail,
    String? relationshipToChild,
    String? status,
    bool? paymentRequired,
    double? applicationFee,
    bool? paymentCompleted,
    DateTime? paymentDate,
    String? paymentReference,
    bool? isArchived,
    DateTime? archivedDate,
    String? archivedBy,
    String? archiveReason,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewNotes,
    bool? certificateApplicationCompleted,
    DateTime? certificateApplicationDate,
    String? certificateNumber,
  }) {
    return ABNApplication(
      id: id ?? this.id,
      birthRecordId: birthRecordId ?? this.birthRecordId,
      applicationNumber: applicationNumber ?? this.applicationNumber,
      applicationDate: applicationDate ?? this.applicationDate,
      applicantName: applicantName ?? this.applicantName,
      applicantId: applicantId ?? this.applicantId,
      applicantPhone: applicantPhone ?? this.applicantPhone,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      relationshipToChild: relationshipToChild ?? this.relationshipToChild,
      status: status ?? this.status,
      paymentRequired: paymentRequired ?? this.paymentRequired,
      applicationFee: applicationFee ?? this.applicationFee,
      paymentCompleted: paymentCompleted ?? this.paymentCompleted,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentReference: paymentReference ?? this.paymentReference,
      isArchived: isArchived ?? this.isArchived,
      archivedDate: archivedDate ?? this.archivedDate,
      archivedBy: archivedBy ?? this.archivedBy,
      archiveReason: archiveReason ?? this.archiveReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      certificateApplicationCompleted: certificateApplicationCompleted ?? this.certificateApplicationCompleted,
      certificateApplicationDate: certificateApplicationDate ?? this.certificateApplicationDate,
      certificateNumber: certificateNumber ?? this.certificateNumber,
    );
  }
}

