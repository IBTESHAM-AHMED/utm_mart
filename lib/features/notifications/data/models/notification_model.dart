import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum NotificationType {
  orderStatusChange,
  orderWaitingApproval,
  auctionOutbid,
  auctionWon,
  auctionEnded,
  auctionCreated,
  general,
}

enum NotificationStatus { unread, read }

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationStatus status;
  final DateTime createdAt;
  final Map<String, dynamic>?
  data; // Additional data like orderId, auctionId, etc.
  final String? imageUrl;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    required this.createdAt,
    this.data,
    this.imageUrl,
  });

  // Factory constructor for creating from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => NotificationType.general,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => NotificationStatus.unread,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      data: data['data'] as Map<String, dynamic>?,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString(),
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
      'imageUrl': imageUrl,
    };
  }

  // Copy with method for updating
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationStatus? status,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Get display icon based on notification type
  String get iconName {
    switch (type) {
      case NotificationType.orderStatusChange:
        return 'order_status';
      case NotificationType.orderWaitingApproval:
        return 'waiting_approval';
      case NotificationType.auctionOutbid:
        return 'auction_outbid';
      case NotificationType.auctionWon:
        return 'auction_won';
      case NotificationType.auctionEnded:
        return 'auction_ended';
      case NotificationType.auctionCreated:
        return 'auction_created';
      case NotificationType.general:
        return 'general';
    }
  }

  // Get color based on notification type
  String get colorHex {
    switch (type) {
      case NotificationType.orderStatusChange:
        return '#4CAF50'; // Green
      case NotificationType.orderWaitingApproval:
        return '#FF9800'; // Orange
      case NotificationType.auctionOutbid:
        return '#F44336'; // Red
      case NotificationType.auctionWon:
        return '#4CAF50'; // Green
      case NotificationType.auctionEnded:
        return '#9E9E9E'; // Grey
      case NotificationType.auctionCreated:
        return '#2196F3'; // Blue
      case NotificationType.general:
        return '#607D8B'; // Blue Grey
    }
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    message,
    type,
    status,
    createdAt,
    data,
    imageUrl,
  ];
}

