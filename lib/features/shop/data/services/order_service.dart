import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/features/auth/data/models/firestore_user_model.dart';
import 'package:utmmart/features/shop/data/models/cart_item_model.dart';
import 'package:utmmart/features/shop/data/services/store_firestore_service.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
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
      await _notificationService.createOrderWaitingApprovalNotification(
        orderId: orderId,
        customerId: customer.uid,
        orderNumber: orderNumber,
      );

      // Update stock for each item
      for (final cartItem in cartItems) {
        await _updateItemStock(cartItem.itemId, cartItem.quantity);
      }

      return true;
    } catch (e) {
      print('Error creating order: $e');
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

        print(
          'Updated stock for item $itemId: $currentStock -> ${newStock < 0 ? 0 : newStock}',
        );
      }
    } catch (e) {
      print('Error updating stock for item $itemId: $e');
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
      print('Error getting customer orders: $e');
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
      print('Error getting seller orders: $e');
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
      print('Error updating order status: $e');
      return false;
    }
  }
}
