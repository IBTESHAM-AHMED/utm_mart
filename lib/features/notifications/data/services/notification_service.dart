import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmmart/features/notifications/data/models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'notifications';

  // Get all notifications for current user
  Stream<List<NotificationModel>> getUserNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get unread notifications count
  Stream<int> getUnreadNotificationsCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: NotificationStatus.unread.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).update({
      'status': NotificationStatus.read.toString(),
    });
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final batch = _firestore.batch();
    final unreadNotifications = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: NotificationStatus.unread.toString())
        .get();

    for (final doc in unreadNotifications.docs) {
      batch.update(doc.reference, {
        'status': NotificationStatus.read.toString(),
      });
    }

    await batch.commit();
  }

  // Create a new notification
  Future<void> createNotification(NotificationModel notification) async {
    await _firestore
        .collection(_collection)
        .doc(notification.id)
        .set(notification.toFirestore());
  }

  // Create order status change notification
  Future<void> createOrderStatusNotification({
    required String orderId,
    required String customerId,
    required String newStatus,
    required String orderNumber,
  }) async {
    final notification = NotificationModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_order_$orderId',
      userId: customerId,
      title: 'Order Status Updated',
      message: 'Your order #$orderNumber status has been updated to $newStatus',
      type: NotificationType.orderStatusChange,
      status: NotificationStatus.unread,
      createdAt: DateTime.now(),
      data: {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'newStatus': newStatus,
      },
    );

    await createNotification(notification);
  }

  // Create order waiting for approval notification
  Future<void> createOrderWaitingApprovalNotification({
    required String orderId,
    required String customerId,
    required String orderNumber,
  }) async {
    final notification = NotificationModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_order_waiting_$orderId',
      userId: customerId,
      title: 'Order Pending Approval',
      message: 'Your order #$orderNumber is waiting for seller approval',
      type: NotificationType.orderWaitingApproval,
      status: NotificationStatus.unread,
      createdAt: DateTime.now(),
      data: {'orderId': orderId, 'orderNumber': orderNumber},
    );

    await createNotification(notification);
  }

  // Create auction outbid notification
  Future<void> createAuctionOutbidNotification({
    required String auctionId,
    required String bidderId,
    required String auctionTitle,
    required double newHighestBid,
  }) async {
    final notification = NotificationModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_auction_outbid_$auctionId',
      userId: bidderId,
      title: 'You\'ve Been Outbid',
      message:
          'Someone bid higher than you on "$auctionTitle". New highest bid: RM${newHighestBid.toStringAsFixed(2)}',
      type: NotificationType.auctionOutbid,
      status: NotificationStatus.unread,
      createdAt: DateTime.now(),
      data: {
        'auctionId': auctionId,
        'auctionTitle': auctionTitle,
        'newHighestBid': newHighestBid,
      },
    );

    await createNotification(notification);
  }

  // Create auction won notification
  Future<void> createAuctionWonNotification({
    required String auctionId,
    required String winnerId,
    required String auctionTitle,
    required double winningBid,
  }) async {
    final notification = NotificationModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_auction_won_$auctionId',
      userId: winnerId,
      title: 'Congratulations! You Won!',
      message:
          'You won the auction for "$auctionTitle" with a bid of RM${winningBid.toStringAsFixed(2)}',
      type: NotificationType.auctionWon,
      status: NotificationStatus.unread,
      createdAt: DateTime.now(),
      data: {
        'auctionId': auctionId,
        'auctionTitle': auctionTitle,
        'winningBid': winningBid,
      },
    );

    await createNotification(notification);
  }

  // Create auction ended notification
  Future<void> createAuctionEndedNotification({
    required String auctionId,
    required String bidderId,
    required String auctionTitle,
  }) async {
    final notification = NotificationModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_auction_ended_$auctionId',
      userId: bidderId,
      title: 'Auction Ended',
      message: 'The auction for "$auctionTitle" has ended',
      type: NotificationType.auctionEnded,
      status: NotificationStatus.unread,
      createdAt: DateTime.now(),
      data: {'auctionId': auctionId, 'auctionTitle': auctionTitle},
    );

    await createNotification(notification);
  }

  // Create auction created notification (for followers or general users)
  Future<void> createAuctionCreatedNotification({
    required String auctionId,
    required String sellerId,
    required String auctionTitle,
    required List<String> userIds, // List of user IDs to notify
  }) async {
    final batch = _firestore.batch();

    for (final userId in userIds) {
      final notification = NotificationModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_auction_created_${auctionId}_$userId',
        userId: userId,
        title: 'New Auction Available',
        message: 'A new auction "$auctionTitle" has been created',
        type: NotificationType.auctionCreated,
        status: NotificationStatus.unread,
        createdAt: DateTime.now(),
        data: {
          'auctionId': auctionId,
          'auctionTitle': auctionTitle,
          'sellerId': sellerId,
        },
      );

      final docRef = _firestore.collection(_collection).doc(notification.id);
      batch.set(docRef, notification.toFirestore());
    }

    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).delete();
  }

  // Delete all notifications for current user
  Future<void> deleteAllNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

