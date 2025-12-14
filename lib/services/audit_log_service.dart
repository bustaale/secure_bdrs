import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuditLog {
  final String id;
  final String action;
  final String userId;
  final String userName;
  final String userEmail;
  final String? recordType;
  final String? recordId;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.action,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.recordType,
    this.recordId,
    this.metadata,
    required this.timestamp,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] ?? '',
      action: map['action'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      recordType: map['recordType'],
      recordId: map['recordId'],
      metadata: map['metadata'],
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'recordType': recordType,
      'recordId': recordId,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class AuditLogService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  static const String _collection = 'audit_logs';

  // Log an action
  static Future<void> logAction(
    String action, {
    String? recordType,
    String? recordId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get user details from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = (userDoc.data() as Map<String, dynamic>?) ?? {};
      
      final log = AuditLog(
        id: _firestore.collection(_collection).doc().id,
        action: action,
        userId: user.uid,
        userName: userData['name'] ?? user.displayName ?? 'Unknown',
        userEmail: user.email ?? userData['email'] ?? 'unknown@example.com',
        recordType: recordType,
        recordId: recordId,
        metadata: metadata,
        timestamp: DateTime.now(),
      );

      await _firestore.collection(_collection).doc(log.id).set(log.toMap());
    } catch (e) {
      print('Error logging action: $e');
      // Don't throw - audit logging should not break the app
    }
  }

  // Get all logs
  static Future<List<AuditLog>> getAllLogs({int? limit}) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) {
            final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
            final map = <String, dynamic>{'id': doc.id};
            map.addAll(data);
            return AuditLog.fromMap(map);
          })
          .toList();
    } catch (e) {
      throw Exception('Error fetching audit logs: $e');
    }
  }

  // Get logs by user
  static Future<List<AuditLog>> getLogsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
            final map = <String, dynamic>{'id': doc.id};
            map.addAll(data);
            return AuditLog.fromMap(map);
          })
          .toList();
    } catch (e) {
      throw Exception('Error fetching user logs: $e');
    }
  }

  // Get logs by record type
  static Future<List<AuditLog>> getLogsByRecordType(String recordType) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('recordType', isEqualTo: recordType)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
            final map = <String, dynamic>{'id': doc.id};
            map.addAll(data);
            return AuditLog.fromMap(map);
          })
          .toList();
    } catch (e) {
      throw Exception('Error fetching record type logs: $e');
    }
  }

  // Stream logs
  static Stream<List<AuditLog>> streamLogs({int? limit}) {
    Query query = _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) {
          final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
          final map = <String, dynamic>{'id': doc.id};
          map.addAll(data);
          return AuditLog.fromMap(map);
        })
        .toList());
  }

  // Get recent activity (last 10)
  static Future<List<AuditLog>> getRecentActivity({int limit = 10}) async {
    return getAllLogs(limit: limit);
  }
}
