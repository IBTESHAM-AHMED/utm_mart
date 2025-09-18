import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
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
    final data = widget.order.data() as Map<String, dynamic>;

    // Extract order data
    final String orderId = widget.order.id;
    final String status = data['status'] ?? 'pending';
    final String paymentStatus = data['paymentStatus'] ?? 'pending';
    final bool isAuctionOrder = data['isAuctionOrder'] == true;
    final double total = (data['total'] ?? 0.0).toDouble();
    final double subtotal = (data['subtotal'] ?? 0.0).toDouble();
    final double tax = (data['tax'] ?? 0.0).toDouble();
    final List<dynamic> items = data['items'] as List? ?? [];
    final Timestamp createdAt = data['createdAt'] as Timestamp;
    final DateTime orderDate = createdAt.toDate();

    // Format date and time
    final String formattedDate = DateFormat('dd MMM, yyyy').format(orderDate);
    final String formattedTime = DateFormat('HH:mm').format(orderDate);

    // Get status color and icon
    final statusInfo = _getStatusInfo(status);

    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.md),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${orderId.substring(0, 12)}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.apply(fontWeightDelta: 2, color: Colors.blue),
                          ),
                          const SizedBox(height: TSizes.xs / 2),
                          // Order Type Badge - Compact
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: TSizes.xs,
                              vertical: TSizes.xs / 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAuctionOrder
                                  ? Colors.purple.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(TSizes.xs),
                              border: Border.all(
                                color: isAuctionOrder
                                    ? Colors.purple
                                    : Colors.green,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAuctionOrder
                                      ? Iconsax.crown
                                      : Iconsax.shopping_cart,
                                  size: 10,
                                  color: isAuctionOrder
                                      ? Colors.purple
                                      : Colors.green,
                                ),
                                const SizedBox(width: TSizes.xs / 4),
                                Text(
                                  isAuctionOrder ? 'AUCTION' : 'BUY',
                                  style: TextStyle(
                                    color: isAuctionOrder
                                        ? Colors.purple
                                        : Colors.green,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TSizes.xs / 2),
                      Text(
                        '$formattedDate at $formattedTime',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.apply(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.md,
                    vertical: TSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.md),
                    border: Border.all(color: statusInfo['color'], width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusInfo['icon'],
                        color: statusInfo['color'],
                        size: 16,
                      ),
                      const SizedBox(width: TSizes.xs),
                      Text(
                        statusInfo['text'].toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium?.apply(
                          color: statusInfo['color'],
                          fontWeightDelta: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.lg),

            // Order Items Section
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(TSizes.md),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_bag, color: Colors.blue, size: 20),
                      const SizedBox(width: TSizes.sm),
                      Text(
                        'Order Items (${items.length})',
                        style: Theme.of(context).textTheme.titleMedium?.apply(
                          fontWeightDelta: 1,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.sm),
                  ...items.map((item) => _buildOrderItemRow(item)).toList(),
                ],
              ),
            ),

            const SizedBox(height: TSizes.lg),

            // Order Summary Section
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(TSizes.md),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt, color: Colors.green, size: 20),
                      const SizedBox(width: TSizes.sm),
                      Text(
                        'Order Summary',
                        style: Theme.of(context).textTheme.titleMedium?.apply(
                          fontWeightDelta: 1,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.sm),
                  _buildSummaryRow(
                    'Subtotal',
                    'RM${subtotal.toStringAsFixed(2)}',
                  ),
                  _buildSummaryRow('Tax', 'RM${tax.toStringAsFixed(2)}'),
                  const Divider(),
                  _buildSummaryRow(
                    'Total',
                    'RM${total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.lg),

            // Payment Status and Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.md,
                      vertical: TSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: _getPaymentStatusColor(
                        paymentStatus,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(TSizes.md),
                      border: Border.all(
                        color: _getPaymentStatusColor(paymentStatus),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Payment: ${paymentStatus.toUpperCase()}',
                      style: Theme.of(context).textTheme.labelMedium?.apply(
                        color: _getPaymentStatusColor(paymentStatus),
                        fontWeightDelta: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(width: TSizes.sm),

                // Add confirmation button for shipped orders
                if (status == 'shipped')
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showReceiveConfirmation(context, orderId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: TSizes.sm,
                          vertical: TSizes.sm,
                        ),
                      ),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text(
                        'Confirm',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build order item row
  Widget _buildOrderItemRow(Map<String, dynamic> item) {
    final String itemName = item['itemName'] ?? 'Unknown Item';
    final int quantity = item['quantity'] ?? 0;
    final double price = (item['itemPrice'] ?? 0.0).toDouble();
    final double totalPrice = (item['totalPrice'] ?? 0.0).toDouble();
    final String itemImage = item['itemImageUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TSizes.sm),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Item Image
          if (itemImage.isNotEmpty)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TSizes.sm),
                image: DecorationImage(
                  image: NetworkImage(itemImage),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(TSizes.sm),
              ),
              child: const Icon(Icons.image, color: Colors.grey),
            ),

          const SizedBox(width: TSizes.sm),

          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: $quantity × RM${price.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Total Price
          Text(
            'RM${totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // Build summary row
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Colors.blue : Colors.black,
            ),
          ),
        ],
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
        return {'text': 'Received', 'icon': Iconsax.box, 'color': Colors.teal};
      case 'closed':
        return {
          'text': 'Completed',
          'icon': Iconsax.verify,
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
