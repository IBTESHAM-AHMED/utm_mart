import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/features/auth/data/models/firestore_user_model.dart';
import 'package:utmmart/features/shop/data/models/cart_item_model.dart';
import 'package:utmmart/features/shop/data/services/store_firestore_service.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/notifications/data/models/notification_model.dart';
import 'package:utmmart/features/notifications/data/services/notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StoreFirestoreService _storeService = sl<StoreFirestoreService>();
  final NotificationService _notificationService = NotificationService();
  final String _ordersCollection = 'orders';

  Future<bool> createOrder({
    required List<CartItemModel> cartItems,
    required FirestoreUserModel customer,
    required double subtotal,
    required double tax,
    required double total,
  }) async {
    try {
      final now = DateTime.now();

      // Create order document
      final orderData = {
        'customerId': customer.uid,
        'customerName': customer.fullName,
        'customerEmail': customer.email,
        'customerPhone': customer.phoneNumber,
        'sellerUid': cartItems.first.sellerUid,
        // Every seller in the cart, so each can query/read their orders.
        'sellerUids': cartItems.map((item) => item.sellerUid).toSet().toList(),
        'items': cartItems
            .map(
              (item) => {
                'itemId': item.itemId,
                'itemName': item.itemName,
                'itemImageUrl': item.itemImageUrl,
                'itemPrice': item.itemPrice,
                'itemBrand': item.itemBrand,
                'itemCategory': item.itemCategory,
                'sellerUid': item.sellerUid,
                'quantity': item.quantity,
                'totalPrice': item.totalPrice,
              },
            )
            .toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'status': 'pending',
        'paymentStatus': 'pending',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      // Add order to Firestore
      final orderDocRef = await _firestore
          .collection(_ordersCollection)
          .add(orderData);
      final orderId = orderDocRef.id;
      final orderNumber = orderId.substring(0, 8);

      // Create notification for customer about order waiting for approval
      try {
        await _notificationService.createOrderWaitingApprovalNotification(
          orderId: orderId,
          customerId: customer.uid,
          orderNumber: orderNumber,
        );
      } catch (e) {
        debugPrint('Customer order notification failed: $e');
      }

      // Tell every seller in the cart about the new order
      for (final sellerUid in cartItems.map((i) => i.sellerUid).toSet()) {
        if (sellerUid == customer.uid) continue;
        await _notificationService.notifyUser(
          userId: sellerUid,
          title: 'New Order Received',
          message:
              'You have a new order #$orderNumber from ${customer.fullName}',
          type: NotificationType.orderStatusChange,
          data: {
            'orderId': orderId,
            'orderNumber': orderNumber,
            'sellerTab': 1,
            'asSeller': true,
          },
        );
      }

      // Update stock for each item
      for (final cartItem in cartItems) {
        await _updateItemStock(cartItem.itemId, cartItem.quantity);
      }

      return true;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return false;
    }
  }

  Future<void> _updateItemStock(String itemId, int purchasedQuantity) async {
    try {
      // Get current item from store
      final itemDoc = await _firestore.collection('store').doc(itemId).get();

      if (itemDoc.exists) {
        final currentStock = itemDoc.data()?['itemStock'] ?? 0;
        final newStock = currentStock - purchasedQuantity;

        // Update stock in store collection
        await _storeService.updateStoreItem(itemId, {
          'itemStock': newStock < 0 ? 0 : newStock, // Prevent negative stock
        });

        debugPrint(
          'Updated stock for item $itemId: $currentStock -> ${newStock < 0 ? 0 : newStock}',
        );
      }
    } catch (e) {
      debugPrint('Error updating stock for item $itemId: $e');
    }
  }

  /// Cancels an order and puts its stock back.
  ///
  /// The seller may cancel until the buyer has received the order; the buyer
  /// may only cancel once it has shipped (to send the item back). The
  /// `stockRestored` flag makes the restore happen at most once.
  Future<void> cancelOrder(String orderId, {required bool byBuyer}) async {
    final orderRef = _firestore.collection(_ordersCollection).doc(orderId);
    late Map<String, dynamic> order;

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(orderRef);
      if (!snap.exists) throw Exception('Order not found');
      order = snap.data()!;

      final status = order['status'] ?? 'pending';
      final allowed = byBuyer
          ? status == 'shipped'
          : const ['pending', 'approved', 'shipped'].contains(status);
      if (!allowed) {
        throw Exception('This order can no longer be cancelled ($status)');
      }
      if (order['stockRestored'] == true) return;

      transaction.update(orderRef, {
        'status': 'cancelled',
        'stockRestored': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Auction orders do not reserve store stock.
      if (order['isAuctionOrder'] != true) {
        for (final item in (order['items'] as List? ?? [])) {
          final itemId = item['itemId'];
          if (itemId is! String || itemId.isEmpty) continue;
          transaction.update(_firestore.collection('store').doc(itemId), {
            'itemStock': FieldValue.increment(item['quantity'] ?? 1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });

    final number = orderId.substring(0, 8);
    if (byBuyer) {
      final sellers = <String>{
        if (order['sellerUid'] is String) order['sellerUid'] as String,
        ...((order['sellerUids'] as List?) ?? []).whereType<String>(),
      };
      for (final sellerUid in sellers) {
        await _notificationService.notifyUser(
          userId: sellerUid,
          title: 'Order Cancelled',
          message: 'The buyer cancelled order #$number and is returning the item',
          type: NotificationType.orderStatusChange,
          data: {'orderId': orderId, 'newStatus': 'cancelled', 'asSeller': true},
        );
      }
    } else if (order['customerId'] is String) {
      await _notificationService.notifyUser(
        userId: order['customerId'] as String,
        title: 'Order Cancelled',
        message: 'The seller cancelled your order #$number',
        type: NotificationType.orderStatusChange,
        data: {'orderId': orderId, 'newStatus': 'cancelled'},
      );
    }
  }

  // Get orders for a specific customer
  Future<List<Map<String, dynamic>>> getCustomerOrders(
    String customerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ordersCollection)
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting customer orders: $e');
      return [];
    }
  }

  // Get orders for a specific seller
  Future<List<Map<String, dynamic>>> getSellerOrders(String sellerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ordersCollection)
          .where('items', arrayContains: {'sellerUid': sellerId})
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting seller orders: $e');
      return [];
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }
}
