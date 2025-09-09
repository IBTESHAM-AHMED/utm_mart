import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/common/view_models/circular_container_view_model.dart';
import 'package:utmmart/core/common/widgets/circular_container.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';
import 'package:intl/intl.dart';

class OrderListItem extends StatefulWidget {
  final QueryDocumentSnapshot order;

  const OrderListItem({super.key, required this.order});

  @override
  State<OrderListItem> createState() => _OrderListItemState();
}

class _OrderListItemState extends State<OrderListItem> {
  final FirebaseService _firebaseService = sl<FirebaseService>();

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final data = widget.order.data() as Map<String, dynamic>;

    // Extract order data
    final String orderId = widget.order.id;
    final String status = data['status'] ?? 'pending';
    final String paymentStatus = data['paymentStatus'] ?? 'pending';
    final double total = (data['total'] ?? 0.0).toDouble();
    final int itemCount = (data['items'] as List?)?.length ?? 0;
    final Timestamp createdAt = data['createdAt'] as Timestamp;
    final DateTime orderDate = createdAt.toDate();

    // Format date
    final String formattedDate = DateFormat('dd MMM, yyyy').format(orderDate);

    // Get status color and icon
    final statusInfo = _getStatusInfo(status);

    return CircularContainer(
      circularContainerModel: CircularContainerModel(
        showBorder: true,
        color: dark ? TColors.dark : TColors.light,
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(statusInfo['icon'], color: statusInfo['color']),
                const SizedBox(width: TSizes.spaceBtwItems / 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusInfo['text'],
                        style: Theme.of(context).textTheme.bodyLarge!.apply(
                          color: statusInfo['color'],
                          fontWeightDelta: 1,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Iconsax.tag),
                      const SizedBox(width: TSizes.spaceBtwItems / 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Order",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              "#${orderId.substring(0, 8)}",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Iconsax.shopping_bag),
                      const SizedBox(width: TSizes.spaceBtwItems / 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Items",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              "$itemCount item${itemCount != 1 ? 's' : ''}",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: \$${total.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.titleMedium?.apply(
                    fontWeightDelta: 1,
                    color: TColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.sm,
                    vertical: TSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(
                      paymentStatus,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.sm),
                    border: Border.all(
                      color: _getPaymentStatusColor(paymentStatus),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    paymentStatus.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.apply(
                      color: _getPaymentStatusColor(paymentStatus),
                      fontWeightDelta: 1,
                    ),
                  ),
                ),
              ],
            ),
            // Add confirmation button for shipped orders
            if (status == 'shipped') ...[
              const SizedBox(height: TSizes.spaceBtwItems),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showReceiveConfirmation(context, orderId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Received'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog for received orders
  void _showReceiveConfirmation(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Received'),
        content: const Text(
          'Have you received this order? This will mark the order as received and close it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmReceived(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Confirm order as received and update stock
  Future<void> _confirmReceived(String orderId) async {
    try {
      print('🔍 Customer confirming order received: $orderId');

      // Get the order data first
      final orderDoc = await _firebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        print('❌ Order document does not exist: $orderId');
        return;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final items = orderData['items'] as List<dynamic>? ?? [];

      print('📦 Found ${items.length} items in order');

      // Update stock for each item BEFORE updating order status
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final itemData = item as Map<String, dynamic>;
        final itemId = itemData['itemId'] as String?;
        final quantity = (itemData['quantity'] as int?) ?? 0;
        final itemName = itemData['itemName'] as String? ?? 'Unknown';

        print('🔍 Processing item $i: $itemName (ID: $itemId, Qty: $quantity)');

        if (itemId != null && quantity > 0) {
          try {
            print('🔍 Getting store document for itemId: $itemId');

            // Get the store document directly by itemId
            final storeDoc = await _firebaseService.firestore
                .collection('store')
                .doc(itemId)
                .get();

            if (storeDoc.exists) {
              final storeData = storeDoc.data() as Map<String, dynamic>;
              final currentStock = (storeData['itemStock'] as int?) ?? 0;

              print('📊 Store item found:');
              print('   - Current stock: $currentStock');
              print('   - Quantity to deduct: $quantity');

              final newStock = currentStock - quantity;

              // Ensure stock doesn't go below 0
              final finalStock = newStock < 0 ? 0 : newStock;

              print(
                '🔄 Updating stock: $currentStock - $quantity = $finalStock',
              );

              await storeDoc.reference.update({
                'itemStock': finalStock,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              print(
                '✅ Successfully updated stock for item $itemId: $currentStock -> $finalStock',
              );
            } else {
              print('❌ Store item not found: $itemId');
            }
          } catch (e) {
            print('❌ Error updating stock for item $itemId: $e');
          }
        } else {
          print('⚠️ Skipping item: itemId=$itemId, quantity=$quantity');
        }
      }

      // Update order status to received AFTER stock is updated
      await _firebaseService.firestore.collection('orders').doc(orderId).update(
        {'status': 'received', 'updatedAt': FieldValue.serverTimestamp()},
      );

      print('✅ Order status updated to received');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Order confirmed as received! Stock has been updated.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error confirming order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'text': 'Pending',
          'icon': Iconsax.clock,
          'color': Colors.orange,
        };
      case 'approved':
        return {
          'text': 'Approved',
          'icon': Iconsax.tick_circle,
          'color': Colors.blue,
        };
      case 'shipped':
        return {
          'text': 'Shipped',
          'icon': Iconsax.ship,
          'color': Colors.purple,
        };
      case 'received':
        return {
          'text': 'Received',
          'icon': Iconsax.tick_circle,
          'color': Colors.green,
        };
      case 'closed':
        return {
          'text': 'Closed',
          'icon': Iconsax.tick_circle,
          'color': Colors.green,
        };
      case 'cancelled':
        return {
          'text': 'Cancelled',
          'icon': Iconsax.close_circle,
          'color': Colors.red,
        };
      case 'returned':
        return {
          'text': 'Returned',
          'icon': Iconsax.arrow_left,
          'color': Colors.orange,
        };
      case 'refunded':
        return {
          'text': 'Refunded',
          'icon': Iconsax.money_send,
          'color': Colors.grey,
        };
      default:
        return {
          'text': 'Unknown',
          'icon': Iconsax.info_circle,
          'color': Colors.grey,
        };
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      case 'partiallyrefunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
