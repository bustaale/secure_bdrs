import 'package:cloud_firestore/cloud_firestore.dart';

class DeathRecord {
  final String id;
  final String name;
  final DateTime dateOfDeath;
  final String placeOfDeath;
  final String cause;
  final String registrationNumber;
  final String? idNumber;
  final String? hospital;
  final String? familyName;
  final String? familyRelation;
  final String? familyPhone;
  final String? gender; // Male or Female
  final int? age; // Age at time of death
  final bool certificateIssued;
  final DateTime? certificateIssuedDate;
  final String? certificateIssuedBy;

  DeathRecord({
    required this.id,
    required this.name,
    required this.dateOfDeath,
    required this.placeOfDeath,
    required this.cause,
    required this.registrationNumber,
    this.idNumber,
    this.hospital,
    this.familyName,
    this.familyRelation,
    this.familyPhone,
    this.gender,
    this.age,
    this.certificateIssued = false,
    this.certificateIssuedDate,
    this.certificateIssuedBy,
  });

  factory DeathRecord.fromJson(Map<String, dynamic> json) => DeathRecord(
        id: json["id"]?.toString() ?? "",
        name: json["name"] ?? "",
        dateOfDeath: DateTime.parse(json["date_of_death"] ?? DateTime.now().toIso8601String()),
        placeOfDeath: json["place_of_death"] ?? "",
        cause: json["cause"] ?? "",
        registrationNumber: json["registration_number"] ?? "",
        idNumber: json["id_number"],
        hospital: json["hospital"],
        familyName: json["family_name"],
        familyRelation: json["family_relation"],
        familyPhone: json["family_phone"],
        gender: json["gender"],
        age: json["age"] != null ? int.tryParse(json["age"].toString()) : null,
        certificateIssued: json["certificateIssued"] ?? false,
        certificateIssuedDate: json["certificateIssuedDate"] != null
            ? DateTime.tryParse(json["certificateIssuedDate"].toString())
            : null,
        certificateIssuedBy: json["certificateIssuedBy"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "date_of_death": dateOfDeath.toIso8601String(),
        "place_of_death": placeOfDeath,
        "cause": cause,
        "registration_number": registrationNumber,
        "id_number": idNumber,
        "hospital": hospital,
        "family_name": familyName,
        "family_relation": familyRelation,
        "family_phone": familyPhone,
        "gender": gender,
        "age": age,
        "certificateIssued": certificateIssued,
        "certificateIssuedDate": certificateIssuedDate?.toIso8601String(),
        "certificateIssuedBy": certificateIssuedBy,
      };

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dateOfDeath': dateOfDeath.toIso8601String(),
      'placeOfDeath': placeOfDeath,
      'cause': cause,
      'registrationNumber': registrationNumber,
      'idNumber': idNumber,
      'hospital': hospital,
      'familyName': familyName,
      'familyRelation': familyRelation,
      'familyPhone': familyPhone,
      'gender': gender,
      'age': age,
      'certificateIssued': certificateIssued,
      'certificateIssuedDate': certificateIssuedDate?.toIso8601String(),
      'certificateIssuedBy': certificateIssuedBy,
    };
  }

  // Create from Map (Firebase)
  factory DeathRecord.fromMap(Map<String, dynamic> map) {
    // Handle Firestore Timestamp
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return DeathRecord(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      dateOfDeath: parseTimestamp(map['dateOfDeath']),
      placeOfDeath: map['placeOfDeath'] ?? '',
      cause: map['cause'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      idNumber: map['idNumber'],
      hospital: map['hospital'],
      familyName: map['familyName'],
      familyRelation: map['familyRelation'],
      familyPhone: map['familyPhone'],
      gender: map['gender'],
      age: map['age'] != null ? (map['age'] is int ? map['age'] : int.tryParse(map['age'].toString())) : null,
      certificateIssued: map['certificateIssued'] ?? false,
      certificateIssuedDate: parseTimestamp(map['certificateIssuedDate']),
      certificateIssuedBy: map['certificateIssuedBy'],
    );
  }
}
