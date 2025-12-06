import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addNotification(NotificationModel notification) async {
    // Generate an ID if one isn't provided (though usually passed in)
    // Here we trust the caller has set ID or we set it if empty.
    String id = notification.id.isEmpty ? const Uuid().v4() : notification.id;
    
    final notificationWithId = notification.copyWith(id: id);

    await _firestore
        .collection('notifications')
        .doc(id)
        .set(notificationWithId.toMap());
  }

  // Stream of notifications, ordered by newest first
  Stream<List<NotificationModel>> getNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
