import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/birth_record.dart';
import '../models/death_record.dart';

enum NotificationType {
  approval,
  rejection,
  system,
  payment,
  certificate,
}

class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? recordType; // 'birth' or 'death'
  final String? recordId;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime timestamp;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.recordType,
    this.recordId,
    this.metadata,
    this.isRead = false,
    required this.timestamp,
  });

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NotificationType.system,
      ),
      recordType: map['recordType'] as String?,
      recordId: map['recordId'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
      isRead: map['isRead'] ?? false,
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : map['timestamp'] is String
              ? DateTime.parse(map['timestamp'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString(),
      'recordType': recordType,
      'recordId': recordId,
      'metadata': metadata,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  static const String _collection = 'notifications';

  /// Send notification to a user
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? recordType,
    String? recordId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notification = Notification(
        id: _firestore.collection(_collection).doc().id,
        userId: userId,
        title: title,
        message: message,
        type: type,
        recordType: recordType,
        recordId: recordId,
        metadata: metadata,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      print('Error sending notification: $e');
      // Don't throw - notifications should not break the app
    }
  }

  /// Notify user of record approval
  static Future<void> notifyApproval({
    required String userId,
    required String recordType, // 'birth' or 'death'
    required String recordId,
    required String recordName,
    String? adminName,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Record Approved',
      message: 'Your $recordType record for "$recordName" has been approved by the administrator.',
      type: NotificationType.approval,
      recordType: recordType,
      recordId: recordId,
      metadata: {
        'adminName': adminName,
        'approvedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Notify user of record rejection
  static Future<void> notifyRejection({
    required String userId,
    required String recordType, // 'birth' or 'death'
    required String recordId,
    required String recordName,
    required String rejectionReason,
    String? adminName,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Record Rejected',
      message: 'Your $recordType record for "$recordName" has been rejected. Reason: $rejectionReason',
      type: NotificationType.rejection,
      recordType: recordType,
      recordId: recordId,
      metadata: {
        'adminName': adminName,
        'rejectionReason': rejectionReason,
        'rejectedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get notifications for a user
  static Future<List<Notification>> getUserNotifications(String userId, {int? limit}) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
        final map = <String, dynamic>{'id': doc.id};
        map.addAll(data);
        return Notification.fromMap(map);
      }).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  static Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Stream notifications for a user
  static Stream<List<Notification>> streamUserNotifications(String userId, {int? limit}) {
    Query query = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
        final map = <String, dynamic>{'id': doc.id};
        map.addAll(data);
        return Notification.fromMap(map);
      }).toList();
    });
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Delete all notifications for a user
  static Future<void> deleteAllUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }
}

